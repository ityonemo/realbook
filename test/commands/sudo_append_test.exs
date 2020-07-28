defmodule RealbookTest.Commands.SudoAppendTest do
  use ExUnit.Case, async: true

  setup do
    random_dirname = Realbook.tmp_dir!
    File.mkdir_p!(random_dirname)

    tmp_filename = 0..0xFFFFFFFF
    |> Enum.random
    |> Integer.to_string(16)

    tmp_dir = Realbook.tmp_dir!()

    path = Path.join(tmp_dir, tmp_filename)
    File.mkdir_p!(tmp_dir)

    File.write!(path, "foo")
    {:ok, path: path}
  end

  describe "sudo_append!/3" do
    setup do
      Realbook.connect!(Realbook.Adapters.Local)
      :ok
    end

    test "works in general", %{path: path} do
      Realbook.set(path: path)
      Realbook.eval("""
      verify false

      play do
        path = get :path
        sudo_send! "foo", path, permissions: 0o644
        sudo_append!("bar", path)
      end
      """)

      assert File.read!(path) == "foobar"
      assert %{
        uid: 0,
        access: :read
      } = File.stat!(path)
    end
  end

  describe "sudo_append!/3 with ssh connection" do
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
        path = get :path
        sudo_send! "foo", path, permissions: 0o644
        sudo_append!("bar", path)
      end
      """)

      assert File.read!(path) == "foobar"
      assert %{
        uid: 0,
        access: :read
      } = File.stat!(path)
    end
  end
end
