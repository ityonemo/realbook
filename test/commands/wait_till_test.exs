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

      assert_receive {:cb, %{count: 3}}

      assert_receive {:cb, %{count: 2}}

      assert_receive {:cb, %{count: 1}}
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

      assert_receive {:cb, %{wait: 50}}

      assert_receive {:cb, %{wait: wait2}}
      assert wait2 > 50

      assert_receive {:cb, %{wait: wait3}}
      assert wait3 > wait2
    end
  end

  describe "when you pass to wait_till" do
    test "a non-integer wait it raises a compile_error" do
      assert_raise CompileError,
        "nofile:4: wait option for wait_till macro must be an integer, got 200.5",
        fn ->
          Realbook.eval("""
          verify false

          play do
            wait_till wait: 200.5 do
            end
          end
          """)
        end
    end

    test "a non-integer count it raises a compile_error" do
      assert_raise CompileError,
        "nofile:4: count option for wait_till macro must be an integer, got 6.4",
        fn ->
          Realbook.eval("""
          verify false

          play do
            wait_till count: 6.4 do
            end
          end
          """)
        end
    end

    test "a backoff <= 1.0 it raises a compile_error" do
      assert_raise CompileError,
        "nofile:4: backoff option for wait_till macro must be a number > 1, got 1.0",
        fn ->
          Realbook.eval("""
          verify false

          play do
            wait_till backoff: 1.0 do
            end
          end
          """)
        end
    end
  end
end
