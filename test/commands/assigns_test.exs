defmodule RealbookTest.Commands.AssignsTest do
  use ExUnit.Case, async: true

  setup do
    Realbook.connect!(Realbook.Adapters.Local)
    :ok
  end

  describe "assigns/1" do
    test "works at compile-time" do
      Realbook.set(
        test_pid: self(),
        foo: "foo",
        bar: "bar")

      Realbook.eval("""
      require EEx

      @data asset!("assign_test.eex")
      EEx.function_from_string(:def, :my_fun, @data, [:assigns])

      verify false

      play do
        test_pid = get :test_pid

        send(test_pid, {:content, my_fun(assigns([:foo, :bar]))})
      end
      """)

      assert_receive {:content, "foobar\n"}
    end

    test "assigns can be pipelined into" do
      Realbook.set(foo: "foo")

      Realbook.eval("""
      verify false

      play do
        result = [:foo]
        |> assigns |> Map.get(:foo)
        |> Kernel.<>("bar")

        send(self(), {:result, result})
      end
      """)

      assert_receive {:result, "foobar"}
    end

  end

  describe "when there's a key that isn't there" do
    test "realbook fails" do
      import Realbook

      # only set foo, but not bar.
      Realbook.set(foo: "foo")

      assert_raise KeyError,
      "key :bar not found, expected by #{__ENV__.file} (line #{__ENV__.line + 9})", fn ->
        ~B"""
        require EEx

        EEx.function_from_file(:def, :my_fun, asset_path!("assign_test.eex"), [:assigns])

        verify false

        play do
          my_fun(assigns([:foo, :bar]))
        end
        """
      end
    end
  end
end
