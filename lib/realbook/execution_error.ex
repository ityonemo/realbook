defmodule Realbook.ExecutionError do
  defexception name: nil,
    stage: nil,
    module: nil,
    file: nil,
    line: nil,
    cmd: nil,
    retcode: nil,
    error: nil,
    msg: nil

  def message(e = %{msg: msg}) when not is_nil(msg) do
    message(%{e | msg: nil})
    |> String.trim(",")
    |> Kernel.<>(": #{msg}")
  end
  def message(e = %{error: error}) when not is_nil(error) do
    message(%{e | error: nil}) <> ", with error #{error}"
  end
  def message(e = %{retcode: retcode}) when not is_nil(retcode) do
    message(%{e | retcode: nil}) <> ", with retcode #{retcode}"
  end
  def message(e = %{line: line}) when not is_nil(line) do
    message(%{e | line: nil}) <> ~s[, (line #{line})]
  end
  def message(e = %{cmd: cmd}) when not is_nil(cmd) do
    message(%{e | cmd: nil}) <> ~s(, command #{cmd})
  end
  def message(%{name: name, stage: stage}) do
    "error in #{name}, stage: #{stage}"
  end
end

defmodule Realbook.ConnectionError do
  defexception message: "generic connection error"
end
