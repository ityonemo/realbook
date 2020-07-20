defmodule RealbookTest.Commands.AssetTest do
  use ExUnit.Case, async: true

  setup do
    Realbook.connect!(Realbook.Adapters.Local)
    :ok
  end

  describe "asset!/3" do
    test "works at compile-time" do
      Realbook.set(test_pid: self())

      Realbook.eval("""

      @foo asset!("foo.txt")

      verify false

      play do
        send((get :test_pid), {:content, @foo})
      end
      """)

      assert_receive {:content, "foo" <> _}
    end

    test "works at runtime" do
      Realbook.set(test_pid: self())

      Realbook.eval("""
      verify false

      play do
        send((get :test_pid), {:content, asset!("foo.txt")})
      end
      """)

      assert_receive {:content, "foo" <> _}
    end
  end
end
