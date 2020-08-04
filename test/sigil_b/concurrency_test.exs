defmodule RealbookTest.SigilB.ConcurrencyTest do
  use ExUnit.Case, async: true

  import Realbook

  # makes sure that sigil-b (and indeed all modules)
  # can be compiled concurrently without problems.

  def compilation(idx, test_pid) do
    spawn fn ->
      Realbook.connect!(:local)
      Realbook.set(test_pid: test_pid, idx: idx)
      ~B"""
      verify false
      play do
        send((get :test_pid), {:done, (get :idx)})
      end
      """
    end
  end

  test "sigil-bs can be run concurrently" do
    test_pid = self()
    1..4
    |> Task.async_stream(&compilation(&1, test_pid))
    |> Stream.run

    for idx <- 1..4 do
      assert_receive({:done, ^idx}, 1000)
    end
  end
end
