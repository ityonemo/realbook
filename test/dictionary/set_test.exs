defmodule RealbookTest.Dictionary.SetTest do
  use ExUnit.Case, async: true

  alias Realbook.Storage

  test "when you use set it sets the dictionary" do
    Realbook.Dictionary.set(foo: "bar")
    assert "bar" == Storage.props(:dictionary)[:foo]

    # resetting it works

    Realbook.Dictionary.set(baz: "quux")
    assert "bar" == Storage.props(:dictionary)[:foo]
  end

  test "same effect happens when using it indirectly" do
    Realbook.set(foo: "bar")
    assert "bar" == Storage.props(:dictionary)[:foo]

    # resetting it works

    Realbook.set(baz: "quux")
    assert "bar" == Storage.props(:dictionary)[:foo]
  end

end
