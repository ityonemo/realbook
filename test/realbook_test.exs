defmodule RealbookTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, tmp_dir: Realbook.tmp_dir!()}
  end

  test "basic realbook can be run", %{tmp_dir: tmp_dir} do

    Realbook.connect!(Realbook.Adapters.Local)
    Realbook.set(dirname: tmp_dir)

    Realbook.run("basic.exs")

    assert File.dir?(tmp_dir)
    assert Realbook.Scripts.Basic in Realbook.props().completed
  end

  test "basic realbook can be with local as an atom", %{tmp_dir: tmp_dir} do
    Realbook.connect!(:local)
    Realbook.set(dirname: tmp_dir)

    Realbook.run("basic.exs")

    assert File.dir?(tmp_dir)
    assert Realbook.Scripts.Basic in Realbook.props().completed
  end

  @tag :one
  test "realbook will fail if the conn hasn't been set", %{tmp_dir: tmp_dir} do
    assert_raise RuntimeError, "can't run realbook on #{inspect self()}: not connected", fn ->
      Realbook.set(dirname: tmp_dir)
      Realbook.run("basic.exs")
    end
  end

end
