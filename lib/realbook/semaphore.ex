defmodule Realbook.Semaphore do
  @moduledoc false
  use GenServer

  # a compiler semaphore for Realbook which ensures that
  # only one compilation unit attempts to compile a module
  # at a time

  @type state :: %{optional(module) => [GenServer.from]}

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_), do: {:ok, %{}}

  @spec lock(term, timeout) :: :locked
  def lock(what, timeout \\ 5000) do
    last_time = DateTime.utc_now()
    case GenServer.call(__MODULE__, {:lock, what}, timeout) do
      :locked -> :locked
      :cleared ->
        time_left = timeout - DateTime.diff(DateTime.utc_now(), last_time, :millisecond)
        unless timeout > 0 do
          raise "timed out"
        end
        lock(what, time_left)
    end
  end
  defp lock_impl(what, from, lock_list) when is_map_key(lock_list, what) do
    # if we aren't the first one here, we have to add ourselves to the list
    # of processes that need to be notified to be unlocked.
    {:noreply, Map.put(lock_list, what, [from | lock_list[what]])}
  end
  defp lock_impl(what, _from, lock_list) do
    # if we are the first here, reply with :locked, which means that once
    # compilation is completed, we have to reply with an :unlock.
    # store an empty list of prospective processes we have to notify back
    # on completion.
    {:reply, :locked, Map.put(lock_list, what, [])}
  end

  @spec unlock(term) :: module
  def unlock(what), do: GenServer.call(__MODULE__, {:unlock, what})

  defp unlock_impl({pid, what}, lock_list) when is_pid(pid) do
    true_key = cond do
      Map.has_key?(lock_list, {:global, what}) -> {:global, what}
      Map.has_key?(lock_list, {pid, what}) -> {pid, what}
      true -> raise "key #{inspect what} not found"
    end
    unlock_impl_common(true_key, lock_list)
  end
  defp unlock_impl(what, lock_list), do: unlock_impl_common(what, lock_list)

  defp unlock_impl_common(what, lock_list) do
    # the locking process has finished its compilation and so it needs to
    # release all of the modules, then it needs to clear the list of
    # things that need bo contacted.
    Enum.each(lock_list[what], &GenServer.reply(&1, :cleared))
    {:reply, what, Map.delete(lock_list, what)}
  end

  @impl true
  def handle_call({:lock, what}, from, lock_list) do
    lock_impl(what, from, lock_list)
  end
  def handle_call({:unlock, what}, _from, lock_list) do
    unlock_impl(what, lock_list)
  end

end
