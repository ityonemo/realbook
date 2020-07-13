defmodule Realbook.Adapters.SSH do

  @behaviour Realbook.Adapters.Api
  def connect(opts) do
    SSH.connect(opts[:host], Keyword.drop(opts, [:host]))
  end

  @falsy [nil, false]

  defdelegate run(conn, cmd, opts), to: SSH

  def send(conn, content, remote_file, options) do
    with :ok <- SSH.send(conn, content, remote_file, Keyword.drop(options, [:sudo])),
         true <- options[:sudo],
         {:ok, _, 0} <- run(conn, "sudo chown root:root #{remote_file}", []) do
      :ok
    else
      falsy when falsy in @falsy -> :ok
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
