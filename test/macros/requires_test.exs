defmodule RealbookTest.Macros.RequiresTest do
  use ExUnit.Case, async: true

  setup do
    Realbook.connect!(:local)
    Realbook.set(test_pid: self())
  end

  @moduletag :requires

  describe "Realbook.Macro.requires/1" do
    test "will preload and execute a dependency" do
      Realbook.eval("""
      requires "dependency.exs"

      verify false

      play do
      end
      """)

      assert_receive :dependency
      assert Realbook.Scripts.Dependency in Realbook.props().completed
    end

    test "will preload and execute a dependency without .exs" do
      Realbook.eval("""
      requires "dependency"

      verify false

      play do
      end
      """)

      assert_receive :dependency
      assert Realbook.Scripts.Dependency in Realbook.props().completed
    end

    test "will execute word lists" do
      Realbook.eval("""
      requires ~w(dependency)

      verify false

      play do
      end
      """)

      assert_receive :dependency
      assert Realbook.Scripts.Dependency in Realbook.props().completed
    end

    test "will preload and execute a comptime variable" do
      Realbook.eval("""
      dependency = "dependency.exs"
      requires dependency

      verify false

      play do
      end
      """)

      assert_receive :dependency
      assert Realbook.Scripts.Dependency in Realbook.props().completed
    end
  end
end
