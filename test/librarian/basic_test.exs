defmodule RealbookTest.Librarian.BasicTest do
  use ExUnit.Case, async: true

  test "librarian-based actions" do
    random_dirname = Realbook.tmp_dir!()

    username = case System.cmd("whoami", []) do
      {res, 0} -> String.trim(res)
    end

    Realbook.connect!(Realbook.Adapters.SSH, host: "localhost", user: username)

    Realbook.set(dirname: random_dirname)

    Realbook.run("basic.exs")

    assert File.dir?(random_dirname)
  end

  test "you can use an atom to select the addapter" do
    random_dirname = Realbook.tmp_dir!()

    username = case System.cmd("whoami", []) do
      {res, 0} -> String.trim(res)
    end

    Realbook.connect!(:ssh, host: "localhost", user: username)

    Realbook.set(dirname: random_dirname)

    Realbook.run("basic.exs")

    assert File.dir?(random_dirname)
  end
end
