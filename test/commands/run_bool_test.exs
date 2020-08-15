defmodule RealbookTest.Commands.RunBoolTest do
  use ExUnit.Case, async: true

  describe "basic run_bool!/2" do
    setup do
      Realbook.connect!(Realbook.Adapters.Local)
      :ok
    end

    test "works in play" do
      Realbook.eval("""
      verify false

      play do
        true_v = run_bool! "true"
        false_v = run_bool! "false"
        send(self(), {:run_bool, true_v, false_v})
      end
      """)

      assert_receive {:run_bool, true, false}
    end
  end
end
