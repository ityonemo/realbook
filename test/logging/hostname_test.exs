defmodule RealbookTest.Logging.HostnameTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog

  @moduletag :logging

  def play_empty_realbook do
    Realbook.eval("""
    verify false
    play do end
    """)
  end

  describe "when you run a realbook it" do
    test "logs the localhost for the local connection" do
      Realbook.connect!(:local)

      log = capture_log &play_empty_realbook/0

      assert log =~ "playing anonymous Realbook on localhost"
    end

    test "can be assigned an alternate name" do
      Realbook.connect!(:local, alt_name: "foo")

      log = capture_log &play_empty_realbook/0

      assert log =~ "playing anonymous Realbook on foo"
    end

    test "text-prints the ip address in the case of IP" do
      Realbook.connect!(:ssh, host: {127, 0, 0, 1})

      log = capture_log &play_empty_realbook/0

      assert log =~ "playing anonymous Realbook on 127.0.0.1"
    end

    test "text-prints the ip address in the case of a string" do
      Realbook.connect!(:ssh, host: "localhost")

      log = capture_log &play_empty_realbook/0

      assert log =~ "playing anonymous Realbook on localhost"
    end

    test "when skipping also it does the right thing" do
      Realbook.connect!(:local)

      log = capture_log fn -> Realbook.eval("""
        verify do
          true
        end

        play do end
        """)
      end

      assert log =~ "skipping anonymous Realbook on localhost"
    end

  end

  describe "the log command" do
    test "concatenates the logger command" do
      Realbook.connect!(:local, alt_name: "bar")

      log = capture_log fn -> Realbook.eval("""
          verify false
          play do
            log "foo"
          end
          """)
        end

      assert log =~ "(bar): foo"
    end
  end

end
