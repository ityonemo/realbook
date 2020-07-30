defmodule Realbook.Adapters.SSH do

  @moduledoc """

  ## Tips:
  - you might need this option:
    `silently_accept_hosts: true`
  """

  @behaviour Realbook.Adapters.Api
  def connect(opts) do
    SSH.connect(opts[:host], Keyword.drop(opts, [:host]))
  end

  defdelegate run(conn, cmd, opts), to: SSH

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
