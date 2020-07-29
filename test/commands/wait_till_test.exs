defmodule RealbookTest.Commands.WaitTillTest do

  use ExUnit.Case, async: true

  describe "trying to execute a realbook that requires a value" do

    setup do
      Realbook.connect!(:local)
      :ok
    end

    test "fails if it hasn't been set" do
      Realbook.eval(~S"""
      verify false

      play do
        future = run!("date +%s")
        |> String.trim
        |> String.to_integer
        |> Kernel.+(1)

        wait_till count: 3 do
          now = run!("date +%s")
          run!("test #{future} -lt #{now}")
        end
      end
      """)
    end

    test "fails time expires" do
      assert_raise Realbook.ExecutionError, fn ->
        Realbook.eval(~S"""
        verify false

        play do
          future = run!("date +%s")
          |> String.trim
          |> String.to_integer
          |> Kernel.+(1)

          wait_till wait: 50 do
            now = run!("date +%s")
            run!("test #{future} -lt #{now}")
          end
        end
        """)
      end
    end

    test "callback works" do
      error = "error in anonymous Realbook, stage: play, command wait_till, (line 9)"
      assert_raise Realbook.ExecutionError, error, fn ->
        Realbook.eval("""
        verify false

        defp cb(opts) do
          send(self(), {:cb, opts})
          opts
        end

        play do
          wait_till wait: 50, count: 3, callback: &cb/1 do
            false
          end
        end
        """)
      end

      assert_receive {:cb, opts}
      assert opts[:count] == 3

      assert_receive {:cb, opts}
      assert opts[:count] == 2

      assert_receive {:cb, opts}
      assert opts[:count] == 1
    end

    test "exponential callback works" do
      assert_raise Realbook.ExecutionError, fn ->
        Realbook.eval("""
        verify false

        defp cb(opts) do
          send(self(), {:cb, opts})
          opts
        end

        play do
          wait_till wait: 50, count: 3, backoff: 1.2, callback: &cb/1 do
            false
          end
        end
        """)
      end

      assert_receive {:cb, opts1}
      wait1 = opts1[:wait]
      assert wait1 == 50

      assert_receive {:cb, opts2}
      wait2 = opts2[:wait]
      assert wait2 > wait1

      assert_receive {:cb, opts3}
      wait3 = opts3[:wait]
      assert wait3 > wait2
    end
  end
end
