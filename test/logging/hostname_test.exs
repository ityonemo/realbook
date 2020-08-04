defmodule RealbookTest.Logging.HostnameTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog

  @moduletag :logging

  describe "when you run a realbook it" do
    test "logs the localhost for the local connection" do
      Realbook.connect!(:local)

      log = capture_log fn -> Realbook.eval("""
          verify false
          play do end
          """)
        end

      assert log =~ "anonymous Realbook on localhost"
    end

    test "can be assigned an alternate name" do
      Realbook.connect!(:local, alt_name: "foo")

      log = capture_log fn -> Realbook.eval("""
          verify false
          play do end
          """)
        end

      assert log =~ "anonymous Realbook on foo"
    end

    test "text-prints the ip address in the case of IP" do
      Realbook.connect!(:ssh, host: {127, 0, 0, 1})

      log = capture_log fn -> Realbook.eval("""
        verify false
        play do end
        """)
      end

      assert log =~ "anonymous Realbook on 127.0.0.1"
    end

    test "text-prints the ip address in the case of a string" do
      Realbook.connect!(:ssh, host: "localhost")

      log = capture_log fn -> Realbook.eval("""
        verify false
        play do end
        """)
      end

      assert log =~ "anonymous Realbook on localhost"
    end
  end

end
