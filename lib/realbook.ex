defmodule Realbook do

  @moduledoc """
  A simple, imperative DSL for remotely provisioning and setting up
  linux-based servers.

  ## Objectives:

  - convenience
  - idempotency
  - inspectability

  ## Guides

  See Guides for information on how to get started.

  ## Connecting to remote servers

  Realbook provides be default two connection APIs, one of which
  (`:local`) can be used to provision locally.  The other (`:ssh`)
  can be used to provision a remote host.  In order to use the `SSH`
  api, generally, you must have passwordless ssh keys installed in
  the remote server.  This default can be overridden in the `connect!/2`
  function by providing options that correspond to `SSH.connect/2`
  options.
  """

  defstruct [
    dictionary: [],
    conn: nil,
    module: nil,
    stage: nil,
    completed: []
  ]

  @typedoc false
  @type stage_t :: :preverify | :play | :postverify

  @typedoc false
  @type t :: %__MODULE__{
    dictionary: keyword(),
    conn: term,
    module: module,
    stage: stage_t,
    completed: [module]
  }

  alias Realbook.Storage

  #######################################################################
  ## Core functions

  @spec connect!(atom | module, keyword) :: :ok
  @doc """
  initiates a connection, bound to this process, using the specified
  module.  You may also use a shorthand for the connection.

  ## Examples

  ### using explicit naming

  ```
  Realbook.connect!(Realbook.Adapters.Local)
  ```

  ### using shorthand names

  ```
  Realbook.connect!(:ssh, host: host_ip, user: "admin")
  ```
  """
  def connect!(module!, opts \\ []) do
    Code.ensure_loaded?(module!)
    module! = if function_exported?(module!, :connect, 1) do
      module!
    else
      select(module!)
    end

    case module!.connect(opts) do
      {:ok, conn} ->
        Storage.update(conn: conn, module: module!)
        conn
      {:error, reason} when is_binary(reason) or is_atom(reason) ->
        raise Realbook.ConnectionError, message: "error connecting: #{reason}"
    end
  end

  @spec select(atom) :: module
  defp select(:ssh), do: Realbook.Adapters.SSH
  defp select(module) do
    Module.concat(Realbook.Adapters, module |> Atom.to_string |> Macro.camelize)
  end

  @spec run(Path.t) :: :ok | no_return
  @doc """
  loads a script from the suppiled path, compiles it into a Realbook module and
  executes it.

  If the module already exists, then the existing module will be run without
  recompilation.

  ## Warning:

  This does not currently check if the script has changed prior to deciding not
  to recompile, but that safety check may be revised in the future.
  """
  def run(path) do
    :realbook
    |> Application.fetch_env!(:script_dir)
    |> Path.join(path)
    |> File.read!
    |> eval(path)
    :ok
  end

  @spec eval(iodata, Path.t) :: :ok
  @doc """
  generates an Elixir module corresponding to a realbook script string
  or iodata; then evaluates the module, bound to this process.

  If you provide only the script without a file, then the module will
  be an `anonymous` realbook module.

  It is generally not recommended to use this function directly, but
  it may be useful for user debugging purposes or ad-hoc testing via
  the Elixir REPL.

  Only use this function if you know what you are doing.
  """
  def eval(realbook, file \\ "nofile")
  def eval(realbook, file) when is_binary(realbook) do
    module = compile(realbook, file)
    keys = Realbook.Dictionary.keys()

    # check to make sure the conn exists
    Storage.props(:conn) || raise "can't run realbook on #{inspect self()}: not connected"

    # check to make sure that all of the required keys exist in the module
    :attributes
    |> module.__info__()
    |> Keyword.get(:required_keys)
    |> Keyword.keys
    |> Enum.each(fn
      key -> key in keys || raise KeyError, key: key
    end)

    # check to make sure that all of the required assets from the module exist
    Enum.each(module.__info__(:attributes)[:required_assets], fn
      asset ->
        # given that we have an attribute, raise if it doesn't exist.
        :realbook
        |> Application.get_env(:asset_dir)
        |> Kernel.||(raise "the realbook #{realbook} requires assets, and no asset dir has been specified.")
        |> Path.join(asset.path) |> IO.inspect(label: "151")
        |> File.exists?
        |> unless do
          raise Realbook.AssetError,
            module: module,
            path: asset.path,
            file: asset.file,
            line: asset.line
        end
    end)

    module.__exec__()
    :ok
  end
  def eval(module, "nofile") when is_atom(module) do
    module.__exec__()
    :ok
  end

  @doc false
  # private api, provided as an entrypoint for testing purposes.
  @spec compile(iodata, Path.t) :: module
  def compile(realbook, file) do
    [{mod, _bin}] = realbook
    |> Code.string_to_quoted!(existing_atoms: :safe)
    |> modulewrap(file)
    mod
  end

  ##########################################################################
  ## Dictionary functions

  @spec set(keyword) :: :ok
  @doc """
  puts keys into the Realbook dictionary.

  This is a key-value store which stores "variables" for your Realbook
  scripts.  Note that these key/values are stored in an ets table under the
  Realbook caller's process pid.

  Typically, you will run `set/1` prior to executing the Realbook script to
  satisfy all parameters that the it must have at runtime.  The Realbook script
  performs a compile-time check to identify all necessary parameters and will
  refuse to run unless these parameters have been assigned.

  Note that a spawned task will not have access to the Realbook key/value
  store of its parent.  This may change in the future.
  """
  defdelegate set(keyword), to: Realbook.Dictionary

  @spec get(atom, any) :: term
  @doc """
  retrieves a value from the Realbook dictionary by its corresponding key.

  See `set/1` for details on how the key/values are stored.
  """
  defdelegate get(key, default \\ nil), to: Realbook.Dictionary

  @doc false
  # private api, this function is def public for testing purposes.
  def modulewrap(ast, file) do
    {module, name} = case file do
      "nofile" ->
        tag = ast |> :erlang.phash2 |> :erlang.term_to_binary |> Base.encode16
        {Module.concat(Realbook.Scripts, "Anonymous#{tag}"), nil}
      path ->
        basename = String.trim(path, ".exs")

        baselist = basename
        |> String.split(~r/[\.\/]/)
        |> Enum.map(&Macro.camelize/1)

        module = Module.concat([Realbook.Scripts | baselist])

        {module, basename}
    end
    # check to see if this module already exists.
    if function_exported?(module, :__info__, 1) do
      [{module, nil}]
    else
      module
      |> module_ast(ast, name)
      |> Code.compile_quoted("#{file}")
    end
  end

  @doc false
  def module_ast(module, ast, name) do
    quote do
      defmodule unquote(module) do
        import Realbook.Macros
        import Realbook.Commands
        require Logger

        Realbook.Macros.create_accumulated_attribute(__MODULE__, :required_keys)
        Realbook.Macros.create_accumulated_attribute(__MODULE__, :provides_keys)
        Realbook.Macros.create_accumulated_attribute(__MODULE__, :required_assets)

        unquote(ast)

        def __name__, do: unquote(name)
        def __label__ do
          if name = __name__() do
            "Realbook #{name}"
          else
            "anonymous Realbook"
          end
        end

        Realbook.Macros.__exec__()
      end
    end
  end

  ###########################################################################
  ## PRIVATE API.  may be moved out of this module at any time.

  @doc false
  # private API.
  @spec stage() :: stage_t
  def stage, do: Storage.props(:stage)

  @doc false
  # private API.  Do not use.
  @spec stage(stage_t) :: :ok
  def stage(stage) do
    Storage.update(stage: stage)
  end

  @doc false
  # private API.  Do not use.
  # registers a module as having been completed.
  @spec complete(module) :: :ok
  def complete(module) do
    Storage.update(:completed, &[module | &1])
  end

  @doc false
  # private API, do not use.
  # creates a temporary directory, useful for testing.
  @spec tmp_dir!() :: Path.t
  def tmp_dir! do
    System.tmp_dir!
    |> Path.join(".realbook")
    |> Path.join(Base.encode16(<<Enum.random(0..0xFFFFFFFF)::32>>))
  end

end
