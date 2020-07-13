defmodule Realbook.Adapters.Local do

  @behaviour Realbook.Adapters.Api

  @spec connect(keyword) :: {:ok, :local}
  def connect(_opts), do: {:ok, :local}

  @spec process(String.t) :: [String.t]
  defp process(cmd) do
    # do the stupid thing for now.  We'll need to have smarter parsing over time.
    String.split(cmd)
  end

  ###########################################################################
  ## APPEND AND FRIENDS

  @spec run(:local, any, any) :: {:error, atom} | {:ok, binary, non_neg_integer}
  def run(:local, cmd, opts) do
    [cmd | params] = process(cmd)
    # this needs to marshal data from the system.cmd format to the format
    # that connect expects.
    case System.cmd(cmd, params, filter_ssh_opts(opts)) do
      {result, 0} -> {:ok, result, 0}
      {result, retval} -> {:ok, result, retval}
    end
  rescue
    e in ErlangError ->
      {:error, e.original}
  end

  defp filter_ssh_opts(opts) do
    Keyword.take(opts, [:into, :cd, :env, :arg0, :stderr_to_stdout, :parallelism])
  end

  ###########################################################################
  ## SEND AND FRIENDS

  @spec send(:local, binary, Path.t, keyword) ::
    :ok | {:error, File.posix}
  def send(:local, content, destination, opts) do
    with :ok <- do_send(content, destination, opts),
         :ok <- do_perms(destination, opts) do
      :ok
    end
  end

  @spec do_send(binary, Path.t, keyword) :: :ok | {:error, File.posix}
  defp do_send(content, destination, opts) do
    if opts[:sudo] do
      sudo_send(content, destination)
    else
      File.write(destination, content, Keyword.get(opts, :modes, []))
    end
  end

  @spec sudo_send(binary, Path.t) :: :ok | {:error, atom | binary}
  defp sudo_send(content, destination) do
    # create a temporary directory and then send it from there.
    # there might be a better solution for this, possibly using
    tmp_dir_name = Realbook.tmp_dir!
    File.mkdir_p!(tmp_dir_name)
    tmp_file_path = Path.join(tmp_dir_name, Path.basename(destination))
    # send then move.
    with :ok <- send(:local, content, tmp_file_path, []),
         {_, 0} <- System.cmd("sudo", ["chown", "root:root", tmp_file_path]),
         {_, 0} <- System.cmd("sudo", ["mv", tmp_file_path, destination]) do
      :ok
    else
      e = {:error, _} -> e
      {error, retval} when is_integer(retval) ->
        {:error, "#{String.trim error}(#{retval})"}
    end
  rescue
    e in ErlangError ->
      {:error, e.original}
  end

  defp do_perms(destination, opts) do
    perms = opts[:permissions]
    cond do
      ! perms -> :ok
      opts[:sudo] ->
        System.cmd("sudo", ["chmod", "#{Integer.to_string perms, 8}", destination])
      true ->
        System.cmd("chmod", ["#{Integer.to_string perms, 8}", destination])
    end
    |> case do
      :ok -> :ok
      {_, 0} -> :ok
      {error, retval} when is_integer(retval)->
        {:error, "#{String.trim error}(#{retval})"}
    end
  rescue
    e in ErlangError ->
      {:error, e.original}
  end

  ###########################################################################
  ## APPEND AND FRIENDS

  @writable [:read_write, :write]
  @spec append(:local, binary, Path.t, keyword) :: :ok | {:error, File.posix}
  def append(:local, content, destination, opts) do
    if opts[:sudo] && (File.stat!(destination).access not in @writable) do
      sudo_append(content, destination)
    else
      send(:local, content, destination, opts ++ [modes: [:append]])
    end
  end

  def sudo_append(content, destination) do
    with {_, 0} <- System.cmd("sudo", ["chmod", "o+w", destination]),
         :ok    <- File.write(destination, content, [:append]) do
      :ok
    else
      error = {:error, _} -> error
      {msg, _nonzero} -> {:error, msg}
    end
  after
    System.cmd("sudo", ["chmod", "o-w", destination])
  end


end
