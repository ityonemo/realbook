defmodule RealbookTest.Macros.RequiresTest do
  use ExUnit.Case, async: true

  alias Realbook.Storage

  setup do
    Realbook.connect!(:local)
    Realbook.set(test_pid: self())
  end

  @moduletag :requires

  describe "Realbook.Macro.requires/1" do
    test "will preload and execute a dependency" do
      Realbook.eval("""
      requires "dependency.exs"
      """)

      assert_receive :dependency
      assert Realbook.Scripts.Dependency in Storage.props(:completed)
    end

    test "will preload and execute a dependency without .exs" do
      Realbook.eval("""
      requires "dependency"
      """)

      assert_receive :dependency
      assert Realbook.Scripts.Dependency in Storage.props(:completed)
    end

    test "will execute word lists" do
      Realbook.eval("""
      requires ~w(dependency)
      """)

      assert_receive :dependency
      assert Realbook.Scripts.Dependency in Storage.props(:completed)
    end

    test "will preload and execute a comptime variable" do
      Realbook.eval("""
      dependency = "dependency.exs"
      requires dependency
      """)

      assert_receive :dependency
      assert Realbook.Scripts.Dependency in Storage.props(:completed)
    end

    test "namespaced submodules work" do
      Realbook.eval("""
      requires "submodule.dependency"
      """)

      assert_receive {:dependency, Realbook.Scripts.Submodule.Dependency}
    end

    test "namespaced subdirectories work" do
      Realbook.eval("""
      requires "subdir/dependency"
      """)

      assert_receive {:dependency, Realbook.Scripts.Subdir.Dependency}
    end
  end
end
