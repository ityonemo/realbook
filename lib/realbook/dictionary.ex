defmodule Realbook.Dictionary do
  @moduledoc false
  # private implementation of realbook setters and getters.

  alias Realbook.Storage

  @spec set(keyword) :: :ok
  def set(keyword) do
    Storage.update(:dictionary, &Keyword.merge(&1, keyword))
  end

  @spec get(atom, term) :: term
  def get(key, default \\ nil) do
    dictionary = Storage.props(:dictionary)

    dictionary
    |> Keyword.get(key, default)
    || raise KeyError, key: key,
                       term: dictionary
  end

  @spec keys() :: [atom]
  def keys do
    :dictionary
    |> Storage.props
    |> Keyword.keys
  end

end
