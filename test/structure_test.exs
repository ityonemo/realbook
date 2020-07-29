defmodule RealbookTest.StructureTest do
  # checks to see if the expected structure of a realbook module is generated.
  use ExUnit.Case, async: true

  describe "Realbook.compile/2 can creates an anonymous module" do
    setup do
      module = Realbook.compile("""
      verify false
      play do end
      """, "nofile")

      {:ok, module: module}
    end

    test "generates an anonymous module that exists", %{module: module} do
      # check that the module is in the correct namespace
      assert ["Realbook", "Scripts" | _] = Module.split(module)
      assert function_exported?(module, :__info__, 1)
    end

    test "generates expected handle functions", %{module: module} do
      assert function_exported?(module, :__exec__, 0)
      assert function_exported?(module, :__play__, 0)
      assert function_exported?(module, :__verify__, 1)
      assert function_exported?(module, :__name__, 0)
    end

    test "the module has `nil` for its name", %{module: module} do
      assert is_nil(module.__name__)
    end
  end

  describe "Realbook.compile/2 modules find internal getters" do
    test "and makes them required when they are in play directives" do
      module = Realbook.compile("""
      verify false
      play do
        get :my_value
      end
      """, "nofile")

      assert :my_value in module.__info__(:attributes)[:required_keys]
    end

    test "and makes them required when they are in verify directives" do
      module = Realbook.compile("""
      verify do
        get :my_value
      end
      play do
      end
      """, "nofile")

      assert :my_value in module.__info__(:attributes)[:required_keys]
    end

    test "and makes them required when they are in def or defp directives" do
      module = Realbook.compile("""
      def foo do
        get :foo
      end

      defp bar do
        get :bar
      end

      verify false
      play do
        bar()
      end
      """, "nofile")

      assert :foo in module.__info__(:attributes)[:required_keys]
      assert :bar in module.__info__(:attributes)[:required_keys]
    end

    test "don't make them required when they are set in verify directives" do
      module = Realbook.compile("""
      verify do
        set my_value: 3
      end
      play do
        get :my_value
      end
      """, "nofile")

      refute :my_value in module.__info__(:attributes)[:required_keys]
    end

    test "does not make them required when a default value is provided" do
      module = Realbook.compile("""
      verify false
      play do
        get :my_value, :default
      end
      """, "nofile")

      refute :my_value in module.__info__(:attributes)[:required_keys]
    end
  end

  describe "Realbook.compile/2 modules find internal setters" do
    test "in verify blocks and makes them into provided keys" do
      module = Realbook.compile("""
      verify do
        set my_value: "foo"
      end
      play do
      end
      """, "nofile")

      assert :my_value in module.__info__(:attributes)[:provides_keys]
    end

    test "in play blocks and makes them into provided keys" do
      module = Realbook.compile("""
      verify false
      play do
        set my_value: "foo"
      end
      """, "nofile")

      assert :my_value in module.__info__(:attributes)[:provides_keys]
    end

    test "that suppress getters from being required keys" do
      module = Realbook.compile("""
      verify do
        set my_value: "foo"
      end

      play do
        get :my_value
      end
      """, "nofile")

      refute :my_value in module.__info__(:attributes)[:required_keys]
    end
  end

  describe "when you have requires modules" do
    test "Realbook.compile/2 modules will save them in the module props" do
      module = Realbook.compile("""
      requires "dependency.exs"
      verify false
      play do end
      """, "nofile")

      assert Realbook.Scripts.Dependency in module.__info__(:attributes)[:requires_modules]
      # and it pulls in the test_pid required keys.
      assert :test_pid in module.__info__(:attributes)[:required_keys]
      # and it pulls in the provides keys:
      assert :foo in module.__info__(:attributes)[:provides_keys]
    end
  end

  describe "when you have an asset directive" do

    alias Realbook.Asset
    test "Realbook.compile/2 will save them in the module props" do
      module = Realbook.compile("""
      my_asset = asset!("foo.txt")

      verify false
      play do end
      """, "nofile")

      assert [%Asset{path: "foo.txt"}] = module.__info__(:attributes)[:required_assets]
    end

    @tag :one
    test "asset requirements are transitive" do
      module = Realbook.compile("""
      requires "asset"
      verify false
      play do end
      """, "nofile")

      assert [%Asset{path: "foo.txt"}] == module.__info__(:attributes)[:required_assets]
    end
  end

end
