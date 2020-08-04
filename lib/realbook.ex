defmodule Realbook do

  @moduledoc """
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

  @spec eval(iodata, Path.t, keyword) :: :ok
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
  def eval(realbook, file \\ "nofile", options \\ [line: 0])
  def eval(realbook, file, options) when is_binary(realbook) do
    module = compile(realbook, file, options)
    keys = Realbook.Dictionary.keys()

    # check to make sure the conn exists
    Storage.props(:conn) || raise "can't run realbook on #{inspect self()}: not connected"

    # check to make sure that all of the required keys exist in the module
    :attributes
    |> module.__info__()
    |> Keyword.get(:required_variables)
    |> Enum.each(fn
      {key, spec} ->
        key in keys ||
          raise KeyError,
            message: "key #{inspect key} not found, expected by #{spec.file} (line #{spec.line})"
    end)

    # check to make sure that all of the required assets from the module exist
    Enum.each(module.__info__(:attributes)[:required_assets], fn
      asset ->
        # given that we have an attribute, raise if it doesn't exist.
        :realbook
        |> Application.get_env(:asset_dir)
        |> Kernel.||(raise "the realbook #{realbook} requires assets, and no asset dir has been specified.")
        |> Path.join(asset.path)
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
  def eval(module, _file, _line) when is_atom(module) do
    module.__exec__()
    :ok
  end

  @doc false
  # private api, provided as an entrypoint for testing purposes.
  @spec compile(iodata, Path.t, keyword) :: module
  def compile(realbook, file, options \\ [line: 0]) do
    offset = Keyword.get(options, :line, 0)

    realbook
    |> Code.string_to_quoted!(
        existing_atoms: :safe,
        line: 1 + offset,
        file: file)
    |> modulewrap(file, options)
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
  def modulewrap(ast, file, options) do
    {module, name} = case {file, options[:module]} do
      {_, module} when is_atom(module) and not is_nil(module) ->
        tag = ast |> :erlang.phash2 |> :erlang.term_to_binary |> Base.encode16
        {Module.concat(module, "Anonymous#{tag}"), nil}
      {"nofile", _} ->
        tag = ast |> :erlang.phash2 |> :erlang.term_to_binary |> Base.encode16
        {Module.concat(Realbook.Scripts, "Anonymous#{tag}"), nil}
      {path, _} ->
        basename = String.trim(path, ".exs")

        baselist = basename
        |> String.split(~r/[\.\/]/)
        |> Enum.map(&Macro.camelize/1)

        module = Module.concat([Realbook.Scripts | baselist])

        {module, basename}
    end
    # check to see if this module already exists.

    cond do
      Realbook.CompilerSemaphore.lock(module) == :cleared ->
        module
      function_exported?(module, :__info__, 1) ->
        Realbook.CompilerSemaphore.unlock(module)
      true ->
        module
        |> module_ast(ast, name)
        |> Code.compile_quoted("#{file}")

        Realbook.CompilerSemaphore.unlock(module)
    end
  end

  @doc false
  def module_ast(module, ast, name) do
    quote do
      defmodule unquote(module) do
        import Realbook.Macros
        import Realbook.Commands
        require Logger

        Realbook.Macros.create_accumulated_attribute(__MODULE__, :required_variables)
        Realbook.Macros.create_accumulated_attribute(__MODULE__, :provides_variables)
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

        @before_compile Realbook.Macros
      end
    end
  end

  ###########################################################################
  ## SIGILS

  @doc """
  Compile and execute a realbook starting at this point in the code.

  This form doesn't perform any interpolation.

  This is the recommended entry point for realbooks, though
  you can also use `run/1` to directly run a realbook file.

  ## Example

  ```elixir
  defmodule MyRealbookEntryModule do

    # ...

    def run_realbooks do
      ~B\"""
      requires ~w(realbook1 realbook2 realbook2)

      verify false

      play do
        # ...
        log "running realbooks"
      end
      \"""
    end

  end
  ```

  """
  defmacro sigil_B({:<<>>, _meta, [definition]}, []) do
    file = __CALLER__.file
    line = __CALLER__.line
    quote bind_quoted: [definition: definition, file: file, line: line, module: __CALLER__.module] do
      Realbook.eval(definition, file, line: line, module: module)
    end
  end

  @doc """
  like `sigil_B/2` but lets you interpolate values from the surrounding
  context.
  """
  defmacro sigil_b(code = {:<<>>, _meta, _}, []) do
    file = __CALLER__.file
    line = __CALLER__.line - 1
    quote bind_quoted: [code: code, file: file, line: line, module: __CALLER__.module] do
      Realbook.eval(code, file, line: line, module: module)
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
