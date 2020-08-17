defmodule Realbook.Storage do
  @moduledoc false
  # this module creates an ets table which holds active realbook
  # information for concurrent systems.

  use GenServer

  def start_link(_), do: GenServer.start_link(__MODULE__, nil)

  @impl true
  def init(nil) do
    :ets.new(__MODULE__, [:set, :public, :named_table, read_concurrency: true, write_concurrency: true])
    # hibernates, since the only purpose of this GenServer is to
    # wrap a the ETS table.
    {:ok, nil, :hibernate}
  end

  @spec props() :: Realbook.t
  def props do
    # props are stored in the ets table under the key of the root PID.
    :"$callers"
    |> Process.get([])
    |> prepend_self
    |> Enum.find_value(%Realbook{}, &lookup/1)
  end

  defp lookup(pid) do
    case :ets.lookup(__MODULE__, pid) do
      [] -> nil
      [{_, realbook}] -> realbook
    end
  end

  @spec props(:dictionary) :: Realbook.Dictionary.t
  @spec props(:conn) :: term
  @spec props(:module) :: module
  @spec props(:stage) :: Realbook.stage_t
  @spec props(:completed) :: [module]
  def props(key) when is_atom(key) do
    Map.get(props(), key)
  end

  @spec update(Realbook.t) :: :ok
  @spec update(keyword) :: :ok
  def update(realbook = %Realbook{}) do
    pid = :"$callers"
    |> Process.get([])
    |> prepend_self
    |> Enum.find(&(:ets.lookup(__MODULE__, &1) != []))

    :ets.insert(__MODULE__, {pid || self(), realbook})
    :ok
  end
  def update(lst) when is_list(lst) do
    props()
    |> struct(lst)
    |> update
  end

  @spec update(:dictionary | :completed, (list -> list)) :: :ok
  def update(key, fun) do
    update([{key, fun.(props(key))}])
  end

  ########################################################################
  ## general helpers

  defp prepend_self(lst), do: [self() | lst]
end
