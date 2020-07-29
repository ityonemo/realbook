defmodule RealbookTest.Commands.RunTest do
  use ExUnit.Case, async: true

  describe "basic run!/2" do
    setup do
      Realbook.connect!(Realbook.Adapters.Local)
      :ok
    end

    test "works in play" do
      Realbook.set(test_pid: self())

      Realbook.eval("""
      verify false

      play do
        result = run! "whoami"
        send((get :test_pid), {:result, result})
      end
      """)

      whoami = "whoami"
      |> System.cmd([])
      |> elem(0)
      |> String.trim
      
      assert_receive {:result, ^whoami}
    end

    test "works in verify" do
      test_pid = self()
      whoami = "whoami"
      |> System.cmd([])
      |> elem(0)
      |> String.trim

      alt_pid = spawn fn ->
        receive do
          {:result, ^whoami} ->
            send(test_pid, {:verify, false})
        end

        receive do
          {:result, ^whoami} ->
            send(test_pid, {:verify, true})
        end
      end

      Realbook.set(alt_pid: alt_pid)
      Realbook.eval("""
      verify do
        result = run! "whoami"
        send((get :alt_pid), {:result, result})
        receive do {:verify, verif} -> verif end
      end
      play do end
      """)
    end

    test "will raise when a failing command is run" do
      assert_raise Realbook.ExecutionError,
      "error in anonymous Realbook, stage: play, command run! \"false\", (line 4), with retcode 1",
      fn -> Realbook.eval("""
        verify false

        play do
          run! "false"
        end
        """)
      end
    end

    test "will raise when an invalid command is run" do
      assert_raise Realbook.ExecutionError,
      "error in anonymous Realbook, stage: play, command run! \"not_a_command\", (line 4), with error enoent",
      fn -> Realbook.eval("""
        verify false

        play do
          run! "not_a_command"
        end
        """)
      end
    end

    test "will raise in verify with correct message" do
      assert_raise Realbook.ExecutionError,
      "error in anonymous Realbook, stage: postverify, command run! \"false\", (line 2), with retcode 1",
      fn -> Realbook.eval("""
        verify do
          run! "false"
        end

        play do
        end
        """)
      end
    end
  end

  describe "run!/2 with ssh" do
    setup do
      {username, 0} = System.cmd("whoami", [])
      username = String.trim(username)
      Realbook.connect!(:ssh, host: "localhost", user: username)
      Realbook.set(test_pid: self())
      {:ok, username: username}
    end

    test "will be able to get the username correct", %{username: username} do
      Realbook.eval("""
      verify false

      play do
        result = run! "whoami"
        send((get :test_pid), {:result, result})
      end
      """)

      assert_receive {:result, ^username}
    end
  end

  describe "basic run/2" do
    setup do
      Realbook.connect!(Realbook.Adapters.Local)
      :ok
    end

    test "works in play" do
      Realbook.set(test_pid: self())
      Realbook.eval("""
      verify false

      play do
        result = run "whoami"
        send((get :test_pid), {:result, result})
      end
      """)

      {whoami, 0} = System.cmd("whoami", [])
      assert_receive {:result, {:ok, ^whoami}}
    end
  end
end
