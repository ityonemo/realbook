defmodule RealbookTest.Macros.VerifyTest do
  use ExUnit.Case, async: true

  setup do
    Realbook.set(test_pid: self())
  end

  describe "Realbook.Macro.verify/1" do
    test "prevents execution if it resolves to true" do
      Realbook.eval("""
      verify do
        true
      end

      play do
        (get :test_pid)
        |> send(:playing)
      end
      """)

      refute_receive :playing
    end

    test "raises if it always resolves false" do
      assert_raise Realbook.ExecutionError, "error in anonymous Realbook, stage: verification", fn ->
        Realbook.eval("""
        verify do
          false
        end

        play do
        end
        """)
      end
    end

    test "raises if it always raises" do
      assert_raise Realbook.ExecutionError, "error in anonymous Realbook, stage: verification", fn ->
        Realbook.eval("""
        verify do
          raise "foo"
        end

        play do
        end
        """)
      end
    end
  end
end
