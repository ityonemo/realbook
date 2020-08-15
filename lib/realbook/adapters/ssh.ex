defmodule Realbook.Adapters.SSH do

  @moduledoc """

  ## Tips:
  - you might need this option:
    `silently_accept_hosts: true`
  """

  require IP

  @behaviour Realbook.Adapters.Api

  @impl true
  @spec connect(keyword) :: {:error, any} | {:ok, pid}
  def connect(opts) do
    SSH.connect(opts[:host], Keyword.drop(opts, [:host]))
  end

  @impl true
  @spec name(keyword) :: String.t
  def name(options) do
    case options[:host] do
      host when IP.is_ip(host) ->
        IP.to_string(host)
      hostname -> hostname
    end
  end

  @impl true
  def run(conn, cmd, opts) do
    if dir = opts[:cd] do
      SSH.run(conn, "cd #{dir}; " <> cmd, Keyword.delete(opts, :cd))
    else
      SSH.run(conn, cmd, opts)
    end
  end

  @impl true
  def send(conn, content, remote_file, options) do
    if options[:sudo] do
      sudo_send(conn, content, remote_file, Keyword.delete(options, :sudo))
    else
      SSH.send(conn, content, remote_file, options)
    end
  end

  def sudo_send(conn, content, remote_file, options) do
    provisional_file = Path.basename(remote_file)

    with :ok <- SSH.send(conn, content, provisional_file, options),
         {:ok, _, 0} <- run(conn, "sudo mv #{provisional_file} #{Path.dirname remote_file}", []),
         {:ok, _, 0} <- run(conn, "sudo chown root:root #{remote_file}", []) do
      :ok
    else
      {:ok, msg, retval} ->
        {:error, "#{msg}, return code #{retval}"}
      error -> error
    end
  end

  @impl true
  def append(conn, content, remote_file, options) do
    if options[:sudo] && unwritable?(conn, remote_file) do
      sudo_append(conn, content, remote_file)
    else
      case content do
        content when is_binary(content) -> List.wrap(content)
        _ -> content
      end
      |> Enum.into(SSH.stream!(conn, "tee -a #{remote_file}", options))
      |> Stream.run
      :ok
    end
  rescue
    e in SSH.RunError ->
      {:error, e.message}
  end

  defp unwritable?(conn, remote_file) do
    not match?(<<_, _o::24, _g::24, _r, ?w, _x>> <> _,
      SSH.run!(conn, "stat --format=%A #{remote_file}"))
  end

  def sudo_append(conn, content, remote_file) do
    SSH.run!(conn, "sudo chmod o+w #{remote_file}")
    append(conn, content, remote_file, [])
  after
    SSH.run!(conn, "sudo chmod o-w #{remote_file}")
  end
end
