defmodule RealbookTest do
  use ExUnit.Case

  alias Realbook.Storage

  setup do
    {:ok, tmp_dir: Realbook.tmp_dir!()}
  end

  test "basic realbook can be run", %{tmp_dir: tmp_dir} do

    Realbook.connect!(Realbook.Adapters.Local)
    Realbook.set(dirname: tmp_dir)

    Realbook.run("basic.exs")

    assert File.dir?(tmp_dir)
    assert Realbook.Scripts.Basic in Storage.props(:completed)
  end

  test "basic realbook can be with local as an atom", %{tmp_dir: tmp_dir} do
    Realbook.connect!(:local)
    Realbook.set(dirname: tmp_dir)

    Realbook.run("basic.exs")

    assert File.dir?(tmp_dir)
    assert Realbook.Scripts.Basic in Storage.props(:completed)
  end

  test "realbook will fail if the conn hasn't been set", %{tmp_dir: tmp_dir} do
    assert_raise RuntimeError, "can't run realbook on #{inspect self()}: not connected", fn ->
      Realbook.set(dirname: tmp_dir)
      Realbook.run("basic.exs")
    end
  end

  defmodule SigilBTest do
    import Realbook
    def sigil_b_test1 do
      ~B"""
      verify false
      play do
        send(self(), {:test1, __MODULE__})
      end
      """
    end
  end

  test "the things get made" do
    Realbook.connect!(:local)
    SigilBTest.sigil_b_test1()
    assert_receive {:test1, module_name}

    assert module_name
    |> Module.split
    |> List.last
    |> String.starts_with?("Anonymous")
  end
end
