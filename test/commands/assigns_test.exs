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
  end
end
