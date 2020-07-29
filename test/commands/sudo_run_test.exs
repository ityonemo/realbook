defmodule RealbookTest.Commands.SudoRunTest do
  use ExUnit.Case, async: true

  describe "basic sudo_run!/2" do
    setup do
      Realbook.connect!(Realbook.Adapters.Local)
      :ok
    end

    test "works in play" do
      Realbook.set(test_pid: self())

      Realbook.eval("""
      verify false

      play do
        result = sudo_run! "whoami"
        send((get :test_pid), {:result, result})
      end
      """)

      assert_receive {:result, "root"}
    end

    test "works in verify" do
      test_pid = self()
      alt_pid = spawn fn ->
        receive do
          {:result, "root"} -> send(test_pid, {:verify, false})
        end

        receive do
          {:result, "root"} -> send(test_pid, {:verify, true})
        end
      end

      Realbook.set(alt_pid: alt_pid)
      Realbook.eval("""
      verify do
        result = sudo_run! "whoami"
        send((get :alt_pid), {:result, result})
        receive do {:verify, verif} -> verif end
      end
      play do end
      """)
    end

    test "will raise when a failing command is run" do
      assert_raise Realbook.ExecutionError,
      "error in anonymous Realbook, stage: play, command sudo_run! \"false\", (line 4), with retcode 1",
      fn -> Realbook.eval("""
        verify false

        play do
          sudo_run! "false"
        end
        """)
      end
    end
  end

  describe "sudo_run!/2 with ssh" do
    setup do
      {username, 0} = System.cmd("whoami", [])
      username = String.trim(username)
      Realbook.connect!(:ssh, host: "localhost", user: username)
      Realbook.set(test_pid: self())
      :ok
    end

    test "will be able to get the username correct" do
      Realbook.eval("""
      verify false

      play do
        result = sudo_run! "whoami"
        send((get :test_pid), {:result, result})
      end
      """)

      assert_receive {:result, result}
      assert result =~ "root"
    end
  end


  describe "basic sudo_run/2" do
    setup do
      Realbook.connect!(Realbook.Adapters.Local)
      :ok
    end

    test "works in play" do
      Realbook.set(test_pid: self())
      Realbook.eval("""
      verify false

      play do
        result = sudo_run "whoami"
        send((get :test_pid), {:result, result})
      end
      """)

      assert_receive {:result, {:ok, "root\n"}}
    end
  end

end
