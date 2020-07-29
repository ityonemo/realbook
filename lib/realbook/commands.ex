defmodule Realbook.Commands do
  @moduledoc """
  Command macros that are helper functions for common tasks.

  imported into your Realbook scripts by default.
  """

  @falsy [false, nil]

  @doc false
  def __run__(cmd!, opts!) do
    %{module: module, conn: conn} = Realbook.props()
    {cmd!, opts!} = case Keyword.pop(opts!, :sudo) do
      {falsy, opts!} when falsy in @falsy -> {cmd!, opts!}
      {_, opts!} -> {"sudo " <> cmd!, opts!}
    end
    opts! = process_tty_as(opts!)
    module.run(conn, cmd!, opts!)
  end

  # process tty/as options
  defp process_tty_as(opts) do
    cond do
      # don't change if :as is defined.
      opts[:as] -> opts
      # change tty and stream if tty is true
      opts[:tty] ->
        Keyword.merge(opts, as: :tuple, stderr: :stream)
      true ->
        Keyword.merge(opts, as: :tuple)
    end
  end

  @doc false
  def __send__(symbol, destination, opts) when is_atom(symbol) do
    case Realbook.get(symbol) do
      nil ->
        raise ArgumentError, message: "invalid parameter: `nil`"
      content ->
        __send__(content, destination, opts)
    end
  end
  def __send__({:file, path}, destination, opts) when is_binary(path) do
    case File.read(path) do
      {:ok, content} -> __send__(content, destination, opts)
      error -> error
    end
  end
  def __send__(content, symbol, opts) when is_atom(symbol) do
    case Realbook.get(symbol) do
      filename when is_binary(filename) ->
        __send__(content, filename, opts)
      _ ->
        {:error, "the filename for sending operations must be a String"}
    end
  end
  def __send__(content, destination, opts) do
    %{module: module, conn: conn} = Realbook.props()
    module.send(conn, content, destination, opts)
  end

  @doc false
  def __append__(symbol, destination, opts) when is_atom(symbol) do
    case Realbook.get(symbol) do
      nil ->
        raise ArgumentError, message: "invalid parameter: `nil`"
      content ->
        __append__(content, destination, opts)
    end
  end
  def __append__({:file, path}, destination, opts) when is_binary(path) do
    case File.read(path) do
      {:ok, content} -> __append__(content, destination, opts)
      error -> error
    end
  end
  def __append__(content, symbol, opts) when is_atom(symbol) do
    case Realbook.get(symbol) do
      filename when is_binary(filename) ->
        __append__(content, filename, opts)
      _ ->
        {:error, "the filename for appending operations must be a String"}
    end
  end
  def __append__(content, destination, opts) do
    %{module: module, conn: conn} = Realbook.props()
    module.append(conn, content, destination, opts)
  end

  # run commands
  @doc """
  runs a command on the remote host.

  For options, consult your adapter module.

  raises Realbook.ExecutionError if there is a connection error.

  if the command is executed, returns:

  - `{:ok, stdout}` if the command has zero return code.
  - `{:error, error, retcode}` if the command has nonzero return code.

  """
  defmacro run(cmd, opts \\ []) do
    line = __CALLER__.line
    file = __CALLER__.file
    quote bind_quoted: [cmd: cmd, opts: opts, line: line, file: file] do
      case Realbook.Commands.__run__(cmd, opts) do
        {:ok, {stdout, _stderr}, 0} ->
          {:ok, stdout}
        out = {:ok, stdout, 0} ->
          {:ok, stdout}
        {:ok, {_, stderr}, retcode} ->
          {:error, stderr, retcode}
        {:ok, stdout, retcode} ->
          {:error, stdout, retcode}
        {:error, err} ->
          sudo = opts[:sudo] && "sudo_"
          raise Realbook.ExecutionError,
            name: __label__(),
            stage: Realbook.stage(),
            module: __MODULE__,
            file: file,
            line: line,
            cmd: ~s(#{sudo}run "#{cmd}"),
            error: err
      end
    end
  end

  @doc """
  runs a command on the remote host.

  For options, consult your adapter module.

  raises Realbook.ExecutionError if there is a connection error OR if the
  executed command returns a nonzero return code.

  if the command returns a zero return code, this macro returns
  the standard output of the command.
  """
  defmacro run!(cmd, opts \\ []) do
    line = __CALLER__.line
    file = __CALLER__.file
    quote bind_quoted: [cmd: cmd, opts: opts, line: line, file: file] do
      case Realbook.Commands.__run__(cmd, opts) do
        {:ok, {stdout, _stderr}, 0} ->
          stdout
        {:ok, stdout, 0} ->
          stdout
        {:ok, {_, stderr}, retcode} ->
          sudo = opts[:sudo] && "sudo_"
          raise Realbook.ExecutionError,
            name: __label__(),
            stage: Realbook.stage(),
            module: __MODULE__,
            file: file,
            line: line,
            cmd: ~s(#{sudo}run! "#{cmd}"),
            stderr: stderr,
            retcode: retcode
        {:ok, _, retcode} ->
          sudo = opts[:sudo] && "sudo_"
          raise Realbook.ExecutionError,
            name: __label__(),
            stage: Realbook.stage(),
            module: __MODULE__,
            file: file,
            line: line,
            cmd: ~s(#{sudo}run! "#{cmd}"),
            retcode: retcode
        {:error, err} ->
          sudo = opts[:sudo] && "sudo_"
          raise Realbook.ExecutionError,
            name: __label__(),
            stage: Realbook.stage(),
            module: __MODULE__,
            file: file,
            line: line,
            cmd: ~s(#{sudo}run! "#{cmd}"),
            error: err
      end
    end
  end

  @doc "like `run/2`, except with the command run as superuser"
  defmacro sudo_run(cmd, opts \\ []) do
    # punt to the existing run command.  This may change in the future
    # since certain things like environment variables may have to be handled
    # differently when moving into a SUDO system.
    quote bind_quoted: [cmd: cmd, opts: opts] do
      run(cmd, opts ++ [sudo: true])
    end
  end

  @doc "like `run!/2`, except with the command run as superuser"
  defmacro sudo_run!(cmd, opts \\ []) do
    # punt to the existing run command.  This may change in the future
    # since certain things like environment variables may have to be handled
    # differently when moving into a SUDO system.
    quote bind_quoted: [cmd: cmd, opts: opts] do
      run!(cmd, opts ++ [sudo: true])
    end
  end

  # send commands
  @doc """
  sends binary content to the target.

  returns ok if successful and raises on either a connection error or a
  sending error.
  """
  defmacro send!(content, path, opts \\ []) do
    line = __CALLER__.line
    file = __CALLER__.file
    quote bind_quoted: [content: content, path: path, opts: opts, file: file, line: line] do
      case Realbook.Commands.__send__(content, path, opts) do
        :ok -> :ok
        {:error, error} ->
          sudo = if opts[:sudo], do: "sudo_"
          raise Realbook.ExecutionError,
            name: __label__(),
            stage: Realbook.stage(),
            module: __MODULE__,
            file: file,
            line: line,
            msg: error,
            cmd: "#{sudo}send!"
      end
    end
  end

  @doc """
  like `send/3` but changes posession of the file to superuser after
  transmission.
  """
  defmacro sudo_send!(content, path, opts \\ []) do
    quote bind_quoted: [content: content, path: path, opts: opts] do
      send!(content, path, opts ++ [sudo: true])
    end
  end

  @doc """
  appends binary content to the target file.

  returns ok if successful and raises on either a connection error or a
  sending error.
  """
  defmacro append!(content, path, opts \\ []) do
    line = __CALLER__.line
    file = __CALLER__.file
    quote bind_quoted: [content: content, path: path, opts: opts, file: file, line: line] do
      case Realbook.Commands.__append__(content, path, opts) do
        :ok -> :ok
        {:error, error} ->
          sudo = if opts[:sudo], do: "sudo_"
          raise Realbook.ExecutionError,
            name: __label__(),
            stage: Realbook.stage(),
            module: __MODULE__,
            file: file,
            line: line,
            msg: error,
            cmd: "#{sudo}send!"
      end
    end
  end

  @doc """
  like `append!/3` but useful for files which are owned by superuser.
  """
  defmacro sudo_append!(content, path, opts \\ []) do
    quote bind_quoted: [content: content, path: path, opts: opts] do
      append!(content, path, opts ++ [sudo: true])
    end
  end

  #########################################################################
  # OTHER UTILITIES

  @doc "pauses for `time` milliseconds"
  defmacro sleep(time) do
    quote bind_quoted: [time: time] do
      Process.sleep(time)
    end
  end

  @doc """
  raises `Realbook.ExecutionError` automatically with the issued comment.
  """
  defmacro fail(comment) do
    line = __CALLER__.line
    file = __CALLER__.file
    quote bind_quoted: [file: file, line: line, comment: comment] do
      raise Realbook.ExecutionError,
        name: __label__(),
        stage: Realbook.stage(),
        module: __MODULE__,
        file: file,
        line: line,
        cmd: "fail",
        msg: comment
    end
  end

  @doc """
  sends a log message with canonical realbook metadata and desired message.
  """
  defmacro log(message) do
    quote bind_quoted: [message: message] do
      Logger.info(message)
    end
  end

  alias Realbook.Macros

  ###########################################################################
  ## Getters and setters

  @doc """
  gets a value from the Realbook key/value store.  Registers the
  key as required prior to running the script.
  """
  defmacro get(key) when is_atom(key) do
    module = __CALLER__.module
    unless Macros.has_attribute?(module, :required_keys, key) or
           Macros.has_attribute?(module, :provides_keys, key) do
      Macros.append_attribute(module, :required_keys, key)
    end
    quote do
      Realbook.get(unquote(key))
    end
  end

  @doc """
  gets a value from the Realbook key/value store, providing a default value
  if the key has not been set yet.

  ### Important
  This will not set the value if it has not been set yet.
  """
  def get(key, default) when is_atom(key) do
    Realbook.get(key, default)
  end

  @doc """
  sets key/value pairs into the Realbook key/value store.  Registers
  the keys as provided by the script.
  """
  defmacro set(kv) when is_list(kv) do
    Enum.each(kv, fn {key, _} ->
      Macros.append_attribute(__CALLER__.module, :provides_keys, key)
    end)

    quote do
      Realbook.set(unquote(kv))
    end
  end

  @default_opts Macro.escape(%{wait: 1000, count: 10})

  @doc """
  performs the remote command and repeats it if the command raises or
  returns false.  Useful for events which may take action *after* the command
  is issued, such as `systemctl` actions.

  ## Options
  - `:count` (integer) how many times we should try. Defaults to 10.
  - `:wait` (integer) how many millseconds we should. Defaults to 1000.
  - `:callback` an arity-1 lambda that will be passed the options map
    list each time the system fails.  This map has the following
    fields:
    - `:count` how many times are left
    - `:wait` how many milliseconds will be waited the next round
    - `:backoff` exponential factor for the next wait, must be > 1
    the result of the callback should be updated options; you may also
    save metadata here, if desired; but do not delete the `:count` or
    `:wait` keys.
  - `:backoff` (float)

  ## Example

  ```
  wait_till count: 50 do
    run! "systemctl is-active --quiet my_service"
  end
  ```

  ```
  wait_till count: 10,  do
    run! "some-command"
  end
  ```
  """
  defmacro wait_till(opts \\ [], do: block) do

    # compile-time typechecking on wait_till.
    count = opts[:count]
    if count && (not is_integer(count)) do
      raise CompileError,
        file: __CALLER__.file,
        line: __CALLER__.line,
        description: "count option for wait_till macro must be an integer, got #{inspect count}"
    end

    wait = opts[:wait]
    if wait && (not is_integer(wait)) do
      raise CompileError,
        file: __CALLER__.file,
        line: __CALLER__.line,
        description: "wait option for wait_till macro must be an integer, got #{inspect wait}"
    end

    backoff = opts[:backoff] || 1.2
    if backoff && (not is_number(backoff) || backoff <= 1) do
      raise CompileError,
        file: __CALLER__.file,
        line: __CALLER__.line,
        description: "backoff option for wait_till macro must be a number > 1, got #{inspect backoff}"
    end

    quote do
      initial_opts = Enum.into(unquote(opts), unquote(@default_opts))

      inner_fun = fn ->
        unquote(block)
      end

      # use the Y combinator to recurse over this block.
      y_fn = fn y_fn, opts ->
        new_opts = if callback = opts[:callback] do
          callback.(opts)
        else
          opts
        end

        cond do
          new_opts[:count] == 1 and inner_fun.() ->
            :ok
          new_opts[:count] == 1 ->
            :error
          (try do
            inner_fun.()
          rescue
            _e in Realbook.ExecutionError ->
              false
          end) ->
            :ok
          true ->
            y_fn.(y_fn, Realbook.Commands.__iterate_wait_opts__(new_opts))
        end
      end

      case y_fn.(y_fn, initial_opts) do
        :ok -> :ok
        :error ->
          raise Realbook.ExecutionError,
            name: __label__(),
            stage: Realbook.stage(),
            module: __MODULE__,
            file: unquote(__CALLER__.file),
            line: unquote(__CALLER__.line),
            cmd: "wait_till"
      end
    end
  end

  @doc false
  ## private API.  For advancing options on the "wait" parameter.
  def __iterate_wait_opts__(opts) do
    wait = opts[:wait]
    Process.sleep(wait)

    new_wait = if backoff_factor = opts[:backoff] do
      Enum.random((wait + 1)..trunc(wait * backoff_factor))
    else
      wait
    end

    %{opts | count: opts[:count] - 1, wait: new_wait}
  end

  @doc """
  finds a file at the path (relative to the application env
  variable :realbook, :asset_dir), opens it, and returns the binary.

  raises if :asset_dir is not set or if there is a problem with the file.
  """
  def asset!(file_path) do
    :realbook
    |> Application.fetch_env!(:asset_dir)
    |> Path.join(file_path)
    |> File.read!
  end

end
