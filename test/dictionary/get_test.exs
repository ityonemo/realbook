defmodule RealbookTest.Dictionary.GetTest do
  use ExUnit.Case, async: true

  setup do
    Realbook.set(test_pid: self())
  end

  describe "trying to retrieve dictionary values" do
    test "works with Realbook.Dictionary.get/1" do
      Realbook.Dictionary.set(foo: "bar")

      # resetting it works
      assert "bar" == Realbook.Dictionary.get(:foo)
    end

    test "works with Realbook.get/1" do
      Realbook.Dictionary.set(foo: "bar")

      assert "bar" == Realbook.get(:foo)
    end

    test "fails for Realbook.get/1 if it's unset" do
      assert_raise KeyError, fn ->
        Realbook.get(:foo)
      end
    end

    test "provides a default value for Realbook.get/2" do
      assert "bar" == Realbook.get(:foo, "bar")
      Realbook.Dictionary.set(foo: "baz")
      assert "baz" == Realbook.get(:foo, "bar")
    end
  end

  describe "trying to execute a realbook that requires a value" do

    setup do
      Realbook.set(test_pid: self())
    end

    test "fails if it hasn't been set" do
      assert_raise KeyError, fn ->
        Realbook.eval("""
        verify false

        play do
          (get :test_pid)
          |> send(:playing)

          get :foo
        end
        """)
      end

      # prove that it never even tries to play.
      refute_receive :playing
    end

    test "succeeds if there is a default value" do
      module = Realbook.compile("""
      verify false

      play do
        foo = get :foo, "running"
        (get :test_pid)
        |> send({:msg, foo})
      end
      """, "nofile")

      Realbook.eval(module)
      assert_receive {:msg, "running"}
    end

    test "doesn't use a default value if it's provided" do
      module = Realbook.compile("""
      verify false

      play do
        foo = get :foo, "running"
        (get :test_pid)
        |> send({:msg, foo})
      end
      """, "nofile")

      Realbook.set(foo: "bar")
      Realbook.eval(module)
      assert_receive {:msg, "bar"}
    end
  end

end
