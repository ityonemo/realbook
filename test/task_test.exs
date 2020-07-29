defmodule RealbookTest.TaskTest do
  use ExUnit.Case, async: true

  # makes sure that you can spawn a task

  test "running code inside a task gives access to values" do
    Realbook.connect!(:local)
    Realbook.set(test_pid: self())
    Realbook.eval("""
    verify false

    play do
      Task.async(fn ->
        send((get :test_pid), :verify)
      end)
      |> Task.await
    end
    """)

    assert_receive :verify
  end

  test "running code inside a task can set values" do
    Realbook.connect!(:local)

    Realbook.eval("""
    verify false

    play do
      Task.async(fn ->
        set foo: "bar"
      end)
      |> Task.await
    end
    """)

    assert "bar" == Realbook.get(:foo)
  end

end
