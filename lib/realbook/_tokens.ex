defmodule Realbook.Asset do
  @moduledoc false
  @enforce_keys [:path, :file, :line]
  defstruct @enforce_keys
end

defmodule Realbook.Variable do
  @moduledoc false
  @enforce_keys [:file, :line]
  defstruct @enforce_keys ++ [:type]
end
