defmodule RealbookTest.SigilB.ErrorTest do
  use ExUnit.Case, async: true

  # tests to see if errors in a sigil_b form
  # are correctly passed to the user.

  import Realbook

  def sigil_b_with_error do
    ~B"""
    verify false
    play do
      syntax = %{:error}
    end
    """
  end

  test "syntax errors are propagated" do
    filename = Path.relative_to_cwd(__ENV__.file)
    Realbook.connect!(:local)
    assert_raise SyntaxError,
      "#{filename}:13: syntax error before: '}'",
      &sigil_b_with_error/0
  end

end
