defmodule RealbookTest.Macros.RequiresTest do
  use ExUnit.Case, async: true

  setup do
    Realbook.set(test_pid: self())
  end

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
  end
end
