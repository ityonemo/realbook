defmodule RealbookTest.Commands.SendTest do
  use ExUnit.Case, async: true

  setup do
    random_dirname = Realbook.tmp_dir!
    File.mkdir_p!(random_dirname)

    {:ok, dir: random_dirname}
  end

  describe "send!/2" do
    setup do
      Realbook.connect!(Realbook.Adapters.Local)
      :ok
    end

    test "works in play", %{dir: dir} do
      test_file = Path.join(dir, "foo")
      Realbook.set(test_file: test_file)

      Realbook.eval("""
      verify false

      play do
        send!("bar", get :test_file)
      end
      """)

      assert File.read!(test_file) =~ "bar"
    end

    test "can take a set value directly", %{dir: dir} do
      test_file = Path.join(dir, "foo")
      Realbook.set(test_file: test_file)

      Realbook.eval("""
      verify false

      play do
        send!("bar", :test_file)
      end
      """)

      assert File.read!(test_file) =~ "bar"
    end

    test "can take a content value directly", %{dir: dir} do
      test_file = Path.join(dir, "foo")
      Realbook.set(
        test_file: test_file,
        content: "bar")

      Realbook.eval("""
      verify false

      play do
        send!(:content, :test_file)
      end
      """)

      assert File.read!(test_file) =~ "bar"
    end

    test "can take a file path", %{dir: dir} do
      test_file = Path.join(dir, "foo")
      local_path = Path.join(dir, "bar")
      File.write!(local_path, "bar")
      Realbook.set(
        test_file: test_file,
        local_path: local_path)

      Realbook.eval("""
      verify false

      play do
        local_path = get :local_path
        send!({:file, local_path}, :test_file)
      end
      """)

      assert File.read!(test_file) =~ "bar"
    end

    test "can take a permissions value", %{dir: dir} do
      Realbook.set(
        test_dir: dir,
        test_file: Path.join(dir, "foo"),
        test_pid: self()
      )

      Realbook.eval("""
      @script \"""
      #!/bin/sh
      echo foo
      \"""

      verify false
      play do
        test_file = get :test_file
        send! @script, test_file, permissions: 0o777
        result = run! test_file
        send (get :test_pid), {:result, result}
      end
      """)

      assert_receive {:result, "foo\n"}
    end

    test "raises if the filename symbol is not a String" do
      Realbook.set(test_file: 47)

      assert_raise Realbook.ExecutionError,
        "error in anonymous Realbook, stage: play, command send!, (line 4): the filename for sending operations must be a String",
        fn ->
          Realbook.eval("""
            verify false

            play do
              send!("foo", :test_file)
            end
          """)
        end
    end

    test "will raise when the target directory doesn't exist" do
      # generate a random directory.
      not_a_dir = Realbook.tmp_dir!()
      |> Path.join("foo")

      Realbook.set(not_a_dir: not_a_dir)

      assert_raise Realbook.ExecutionError,
      "error in anonymous Realbook, stage: play, command send!, (line 4): enoent",
      fn -> Realbook.eval("""
        verify false

        play do
          send!("foo", :not_a_dir)
        end
        """)
      end
    end
  end

  describe "send!/2 with ssh" do
    setup do
      {username, 0} = System.cmd("whoami", [])
      username = String.trim(username)
      Realbook.connect!(:ssh, host: "localhost", user: username)
      :ok
    end

    test "will be able to get a sent file" do
      tmp_dir = Realbook.tmp_dir!()
      Realbook.set(tmp_dir: tmp_dir)
      File.mkdir_p!(tmp_dir)

      Realbook.eval("""
      verify false
      play do
        tmp_dir = get(:tmp_dir)
        send!("bar", Path.join(tmp_dir, "foo"))
      end
      """)

      assert (tmp_dir
      |> Path.join("foo")
      |> File.read!) =~ "bar"
    end
  end
end
