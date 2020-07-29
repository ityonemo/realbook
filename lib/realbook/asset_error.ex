defmodule Realbook.AssetError do
  defexception module: nil, path: nil, file: nil, line: nil

  def message(e) do
    ~s/asset "#{e.path}" does not exist in "#{Application.get_env(:realbook, :asset_dir)}", required by module #{e.module}, (#{e.file}) line #{e.line}/
  end
end
