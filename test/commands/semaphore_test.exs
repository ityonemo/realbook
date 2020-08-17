defmodule Realbook.Commands.SemaphoreTest do
  use ExUnit.Case, async: true

  def acquire do
    test_pid = self()
    Agent.get_and_update(__MODULE__, fn
      :ok -> {nil, test_pid}
      _ -> {nil, :error}
    end)
  end

  def release do
    test_pid = self()
    Agent.get_and_update(__MODULE__, fn
      ^test_pid -> {:ok, :ok}
      _ -> {:error, :error}
    end)
  end

  setup do
    {:ok, sem} = Agent.start_link(fn -> :ok end, name: __MODULE__)
    {:ok, sem: sem}
  end

  test "the system has working lock semantics" do
    import Realbook

    Realbook.connect!(:local)

    ~B"""
    verify false

    alias Realbook.Commands.SemaphoreTest

    def task_async(idx) do
      Task.async(fn ->
        lock(:foo)
        SemaphoreTest.acquire()
        res = SemaphoreTest.release()
        Process.sleep(20)
        unlock(:foo)
        res
      end)
    end

    play do
      # make several clones
      res = 1..4
      |> Enum.map(&task_async/1)
      |> Enum.map(&Task.await/1)
      send(self(), {:result, res})
    end
    """

    assert_receive {:result, [:ok, :ok, :ok, :ok]}
  end

  test "the global locks work" do
    import Realbook

    Realbook.connect!(:local)

    ~B"""
    verify false

    alias Realbook.Commands.SemaphoreTest

    def async(idx) do
      test_pid = self()
      spawn(fn ->
        lock(:foo, global: true)
        SemaphoreTest.acquire()
        result = SemaphoreTest.release()
        Process.sleep(20)
        unlock(:foo)
        send(test_pid, {idx, result})
      end)
    end


    play do
      # make several clones
      Enum.map(1..4, &async/1)
    end
    """

    Enum.each(1..4, fn idx ->
      assert_receive {^idx, :ok}
    end)
  end

end
