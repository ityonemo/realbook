defmodule RealbookTest.Commands.SudoSendTest do
  use ExUnit.Case, async: true

  setup do
    random_dirname = Realbook.tmp_dir!
    File.mkdir_p!(random_dirname)

    {:ok, dir: random_dirname}
  end

  describe "sudo_send!/2" do

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
        sudo_send!("bar", get :test_file)
      end
      """)

      assert File.read!(test_file) =~ "bar"
      assert %{uid: 0} = File.stat!(test_file)
    end

    test "can take a set value directly", %{dir: dir} do
      test_file = Path.join(dir, "foo")
      Realbook.set(test_file: test_file)

      Realbook.eval("""
      verify false

      play do
        sudo_send!("bar", :test_file)
      end
      """)

      assert File.read!(test_file) =~ "bar"
      assert %{uid: 0} = File.stat!(test_file)
    end

    test "can take a content value directly", %{dir: dir} do
      test_file = Path.join(dir, "foo")
      Realbook.set(
        test_file: test_file,
        content: "bar")

      Realbook.eval("""
      verify false

      play do
        sudo_send!(:content, :test_file)
      end
      """)

      assert File.read!(test_file) =~ "bar"
      assert %{uid: 0} = File.stat!(test_file)
    end

    test "raises if the filename symbol is not a String" do
      Realbook.set(test_file: 47)

      assert_raise Realbook.ExecutionError,
        "error in anonymous Realbook, stage: play, command sudo_send!, (line 4): the filename for sending operations must be a String",
        fn ->
          Realbook.eval("""
            verify false

            play do
              sudo_send!("foo", :test_file)
            end
          """)
        end
    end

    test "will raise when the target directory doesn't exist" do
      # generate a random directory.
      invalid_path = Realbook.tmp_dir!
      |> Path.join("foo")

      Realbook.set(invalid_path: invalid_path)

      assert_raise Realbook.ExecutionError,
      "error in anonymous Realbook, stage: play, command sudo_send!, (line 4): (1)",
      fn -> Realbook.eval("""
        verify false

        play do
          sudo_send!("foo", :invalid_path)
        end
        """)
      end
    end
  end

  describe "sudo_send!/2 with ssh" do
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

      Process.sleep(100)

      Realbook.eval("""
      verify false
      play do
        tmp_dir = get(:tmp_dir)
        sudo_send!("bar", Path.join(tmp_dir, "foo"))
      end
      """)

      test_file = Path.join(tmp_dir, "foo")

      assert File.read!(test_file) =~ "bar"
      assert %{uid: 0} = File.stat!(test_file)
    end
  end

end
