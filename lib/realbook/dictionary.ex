defmodule Realbook.Dictionary do
  @moduledoc false

  # private implementation of realbook setters and getters.

  @spec set(keyword) :: :ok
  def set(keyword) do
    realbook = Realbook.props()
    dictionary = Keyword.merge(realbook.dictionary, keyword)
    Process.put(:realbook, %{realbook | dictionary: dictionary})
    :ok
  end

  @spec get(atom, term) :: term
  def get(key, default \\ nil) do
    realbook = Realbook.props()

    realbook
    |> Map.get(:dictionary)
    |> Keyword.get(key, default)
    || raise KeyError, key: key,
                       term: realbook.dictionary
  end

  @spec keys() :: [atom]
  def keys do
    Realbook.props()
    |> Map.get(:dictionary)
    |> Keyword.keys
  end

end
