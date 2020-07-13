defmodule RealbookTest.Commands.AppendTest do
  use ExUnit.Case, async: true

  setup do
    random_dirname = Realbook.tmp_dir!
    File.mkdir_p!(random_dirname)
    path = Path.join(random_dirname, "foo")
    File.write!(path, "foo")
    {:ok, path: path}
  end

  describe "append!/3" do
    setup do
      Realbook.connect!(Realbook.Adapters.Local)
      :ok
    end

    test "works in general", %{path: path} do
      Realbook.set(path: path)
      Realbook.eval("""
      verify false

      play do
        append!("bar", get :path)
      end
      """)

      assert File.read!(path) == "foobar"
    end
  end

  describe "append!/3 with ssh connection" do
    setup do
      {username, 0} = System.cmd("whoami", [])
      username = String.trim(username)
      Realbook.connect!(:ssh, host: "localhost", user: username)
      :ok
    end

    test "works", %{path: path} do
      Realbook.set(path: path)
      Realbook.eval("""
      verify false

      play do
        append!("bar", get :path)
      end
      """)

      Process.sleep(50)

      assert File.read!(path) == "foobar"
    end

    test "can fail with correct error" do
      assert_raise Realbook.ExecutionError,
        "error in anonymous Realbook, stage: play, command send!, (line 4): command `tee -a /test` errored with retcode 1",
        fn -> Realbook.eval("""
          verify false

          play do
            append!("bar", "/test")
          end
          """)
        end
    end
  end
end
