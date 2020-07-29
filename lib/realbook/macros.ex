defmodule Realbook.Macros do
  @moduledoc """
  Top-level macros that you will use to build out Realbook scripts.

  These are imported into your Realbook scripts by default.
  """

  @doc """
  defines a list of realbook files which should be run prior to
  running this realbook file.

  ### Usage

  This directive should be at the head of the realbook script.

  ```
  requires "foo.exs"
  ```

  or you may also submit a list of files

  ```
  requires ~w(foo.exs bar.exs baz.exs)
  ```

  ### warning:
  this doesn't currently perform cyclical dependency checks.
  """
  defmacro requires(lst) do
    dependencies = Macro.expand(lst, __CALLER__)

    quote bind_quoted: [dependencies!: dependencies] do

      dependencies! = dependencies!
      |> List.wrap()
      |> Enum.map(&Realbook.Macros.load_module_by_file/1)

      Realbook.Macros.put_module_dependencies(__MODULE__, dependencies!)
      # walk down the dependencies and check for key requirements.
      for dependency <- dependencies! do
        # go through the required keys.  If they were produced by
        # a preceding dependency, then don't add them to required keys
        for key <- dependency.__info__(:attributes)[:required_keys] do
          unless key in Module.get_attribute(__MODULE__, :provides_keys, []) do
            Realbook.Macros.append_attribute(__MODULE__, :required_keys, key)
          end
        end

        for key <- dependency.__info__(:attributes)[:provides_keys] do
          Realbook.Macros.append_attribute(__MODULE__, :provides_keys, key)
        end
      end
    end
  end

  @doc false
  def put_module_dependencies(module, deps) do
    Module.register_attribute(module, :requires_modules, persist: true)
    Module.put_attribute(module, :requires_modules, deps)
  end

  def load_module_by_file(file) do
    file_path = :realbook
    |> Application.get_env(:script_dir)
    |> Path.join(file)

    file_path
    |> normalize!
    |> File.read!
    |> Realbook.compile(file_path)
  end

  defp normalize!(name) do
    cond do
      File.exists?(name) -> name
      File.exists?(name <> ".exs") -> name <> ".exs"
      true ->
        dir = Application.get_env(:realbook, :script_dir)
        raise "could not find realbook script in directory #{dir} corresponding to name #{name}"
    end
  end


  @doc """
  defines actions that *assess the completion* of a realbook script.

  These actions are performed twice.  Once prior to execution, and once
  after execution.  If the first verification stage fails, the `play/1` stage
  is activated.  If it succeeds, the `play/1` stage is not activated.

  The verification is repeated after `play/1`.  If it fails at this stage,
  the system will halt and throw `Realbook.ExecutionError`.

  Typically, the contents of the verification stage should not alter the
  remote target, but only perform analysis of the system.

  To cause the `play/1` block to always execute, you may declare:

  ```elixir
  verify false
  ```

  ### Guidelines

  Verification fails when one of two things happens:

  - any internal directive raises
  - the block returns `false`

  Generally speaking the `verify/2` block should contain a sequence of
  validating `run!` directives which, if any fails causes a failure.  If
  you are retrieving value(s) that need to be compared (for example shasums),
  drop those comparisons as the last test to trigger the final boolean value
  check.

  If you want to quit early on a boolean comparison value and avoid long-running
  or computationally expensive checks, you can use the following type of
  statement:

  ```
  unless <comparison>, do: fail! "failure message"
  ```
  """
  defmacro verify(false) do
    quote do
      def __verify__(:pre), do: false
      def __verify__(:post), do: true
    end
  end

  defmacro verify(do: ast) do
    quote do
      def __verify__(:pre) do
        Realbook.stage(:preverify)
        unquote(ast)
        # on the first pass. trap errors and convert them to `false`
      rescue
        _ -> false
      end
      def __verify__(:post) do
        Realbook.stage(:postverify)
        unquote(ast)
        # on the second pass, trap errors and convert them to ExecutionErrors
      rescue
        e in Realbook.ExecutionError ->
          reraise e, __STACKTRACE__
        _ ->
          reraise Realbook.ExecutionError, [
            name: __label__(),
            stage: :verification
          ], __STACKTRACE__
      end
    end
  end

  @doc """
  defines actions that *perform the operations* of a realbook script

  this action is triggered if `verify/1` fails.  If any event in the `play/1`
  raises, then the system will halt and throw `Realbook.ExecutionError`.
  """
  defmacro play(do: ast) do
    quote do
      def __play__ do
        # execute all required modules.
        :attributes
        |> __MODULE__.__info__()
        |> Keyword.get(:requires_modules, [])
        |> Enum.each(&(&1.__exec__()))

        Realbook.stage(:play)
        unquote(ast)
      end
    end
  end

  @doc false
  # generates an executable function which is the entry point for the module.
  defmacro __exec__() do
    quote do
      def __exec__() do
        cond do
          __MODULE__ in Realbook.Storage.props(:completed) ->
            :ok
          __verify__(:pre) ->
            Realbook.complete(__MODULE__)
            Logger.info(IO.ANSI.bright <> "skipping #{__label__()}")
          true ->
            Logger.info(IO.ANSI.bright <> "playing #{__label__()}")
            __play__()
            __verify__(:post) || raise Realbook.ExecutionError, name: __label__(), stage: :verification
            Realbook.complete(__MODULE__)
            :ok
        end
      end
    end
  end

  #############################################################################
  ## general tools for the compilation phase.

  @doc false
  def create_accumulated_attribute(module, attribute) do
    Module.register_attribute(module, attribute, persist: true)
    Module.put_attribute(module, attribute, [])
  end

  @doc false
  def append_attribute(module, attribute, value) do
    list_so_far = Module.get_attribute(module, attribute)
    Module.put_attribute(module, attribute, [value | list_so_far])
  end

  @doc false
  def has_attribute?(module, attribute, value) do
    value in Module.get_attribute(module, attribute)
  end

end
