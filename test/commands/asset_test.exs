defmodule RealbookTest.Commands.AssetTest do
  use ExUnit.Case, async: true

  setup do
    Realbook.connect!(Realbook.Adapters.Local)
    :ok
  end

  describe "asset!/3" do
    test "works at compile-time" do
      Realbook.eval("""

      @foo asset!("foo.txt")

      verify false

      play do
        send(self(), {:content, @foo})
      end
      """)

      assert_receive {:content, "foo" <> _}
    end

    test "works at runtime" do
      Realbook.eval("""
      verify false

      play do
        send(self(), {:content, asset!("foo.txt")})
      end
      """)

      assert_receive {:content, "foo" <> _}
    end

    test "will throw on launch if the asset doesn't exist" do
      assert_raise Realbook.AssetError, fn ->
        Realbook.eval("""
        verify false

        play do
          asset!("this_does_not_exist")
        end
        """)
      end
    end
  end

  describe "when the asset doesn't exist" do
    test "at compile-time becomes a compile-time error" do
      import Realbook
      assert_raise CompileError, "test/commands/asset_test.exs:#{__ENV__.line + 2}: required asset does-not-exist.txt cannot be loaded (no such file or directory)", fn ->
        ~B"""
        @nope asset!("does-not-exist.txt")

        verify false
        play do end
        """
      end
    end
  end

  describe "asset_path/1" do
    test "will provide the asset path" do
      import Realbook

      ~B"""
      @asset_path asset_path!("foo.txt")

      verify false
      play do
        send(self(), {:asset, @asset_path})
      end
      """

      assert_receive {:asset, asset_path}
      assert "foo.txt" == Path.basename(asset_path)
    end

    test "raises with compiler error if it doesn't exist" do
      import Realbook

      asset_dir = Application.get_env(:realbook, :asset_dir)
      code_file = Path.relative_to_cwd(__ENV__.file)

      assert_raise CompileError,
        "#{code_file}:#{__ENV__.line + 2}: required asset #{asset_dir}/does-not-exist.txt does not exist.", fn ->
        ~B"""
        @asset_path asset_path!("does-not-exist.txt")

        verify false
        play do
          send(self(), {:asset, @asset_path})
        end
        """
      end
    end
  end
end
