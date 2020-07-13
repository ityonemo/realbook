defmodule RealbookTest do
  use ExUnit.Case

  test "basic realbook can be run" do
    random_dir = Realbook.tmp_dir!()

    Realbook.connect!(Realbook.Adapters.Local)
    Realbook.set(dirname: random_dir)

    Realbook.run("basic.exs")

    assert File.dir?(random_dir)
    assert Realbook.Scripts.Basic in Realbook.props().completed
  end

  test "basic realbook can be with local as an atom" do
    random_dir = Realbook.tmp_dir!()

    Realbook.connect!(:local)
    Realbook.set(dirname: random_dir)

    Realbook.run("basic.exs")

    assert File.dir?(random_dir)
    assert Realbook.Scripts.Basic in Realbook.props().completed
  end

end
