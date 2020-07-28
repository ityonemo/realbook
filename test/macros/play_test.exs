defmodule RealbookTest.Macros.PlayTest do
  use ExUnit.Case, async: true

  describe "Realbook.Macro.play/1" do
    test "executes" do
      Realbook.connect!(:local)

      Realbook.set(test_pid: self())

      Realbook.eval("""
      verify false

      play do
        (get :test_pid)
        |> send(:playing)
      end
      """)

      assert_receive :playing
    end
  end
end
