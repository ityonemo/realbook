defmodule RealbookTest.Commands.MiscTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog

  setup do
    Realbook.connect!(Realbook.Adapters.Local)
    :ok
  end

  describe "sleep/1" do
    test "works" do
      test_pid = self()

      sidecar = spawn_link(fn ->
        refute_receive :done, 300
        send(test_pid, :done)
      end)

      Realbook.set(test_pid: self())
      Realbook.eval("""
      verify false

      play do
        sleep 500
      end
      """)

      send(sidecar, :done)
      assert_receive :done
    end
  end

  describe "fail/1" do
    test "works" do
      assert_raise Realbook.ExecutionError, "error in anonymous Realbook, stage: play, command fail, (line 3): for reasons", fn ->
        Realbook.eval("""
        verify false
        play do
          fail "for reasons"
        end
        """)
      end
    end
  end

  describe "log/1" do
    test "works" do
      msg = capture_log fn ->
        Realbook.eval("""
        verify false
        play do
          log "test message"
        end
        """)
      end

      assert msg =~ "test message"
    end
  end
end
