defmodule RealbookTest.ConnectionTest do
  use ExUnit.Case, async: true

  # Tests to make sure that realbook can make usable connections

  alias Realbook.Storage

  defmodule MockConn do
    def connect(opt: :success) do
      {:ok, :conn}
    end
    def connect(:raise) do
      raise "generic error"
    end
    def connect(_) do
      {:error, "bad connection"}
    end

    def name(_), do: "mockconn"
  end

  describe "Realbook.connect!/2" do
    test "returns the conn value when it's an ok tuple" do
      assert :conn == Realbook.connect!(MockConn, opt: :success)

      assert %{
        conn: :conn,
        module: MockConn
      } = Storage.props()
    end

    test "raises if it's not an ok tuple" do
      assert_raise Realbook.ConnectionError, "error connecting: bad connection", fn ->
        Realbook.connect!(MockConn, [])
      end
    end

    test "raises with a connection error if it's a raise" do
      assert_raise RuntimeError, "generic error", fn ->
        Realbook.connect!(MockConn, :raise)
      end
    end
  end

end
