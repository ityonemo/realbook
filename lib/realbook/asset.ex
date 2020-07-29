defmodule Realbook.Asset do

  @moduledoc false

  @enforce_keys [:path, :file, :line]
  defstruct @enforce_keys
end
