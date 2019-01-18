defmodule BlockchainAPIWeb.CoinbaseControllerTest do
  use BlockchainAPIWeb.ConnCase

  alias BlockchainAPI.Explorer
  alias BlockchainAPI.Explorer.Coinbase

  @create_attrs %{
    amount: 42,
    payee: "some payee",
    type: "some type"
  }
  @update_attrs %{
    amount: 43,
    payee: "some updated payee",
    type: "some updated type"
  }
  @invalid_attrs %{amount: nil, payee: nil, type: nil}

  def fixture(:coinbase) do
    {:ok, coinbase} = Explorer.create_coinbase(@create_attrs)
    coinbase
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all coinbase_transactions", %{conn: conn} do
      conn = get(conn, Routes.coinbase_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create coinbase" do
    test "renders coinbase when data is valid", %{conn: conn} do
      conn = post(conn, Routes.coinbase_path(conn, :create), coinbase: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.coinbase_path(conn, :show, id))

      assert %{
               "id" => id,
               "amount" => 42,
               "payee" => "some payee",
               "type" => "some type"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.coinbase_path(conn, :create), coinbase: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update coinbase" do
    setup [:create_coinbase]

    test "renders coinbase when data is valid", %{conn: conn, coinbase: %Coinbase{id: id} = coinbase} do
      conn = put(conn, Routes.coinbase_path(conn, :update, coinbase), coinbase: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.coinbase_path(conn, :show, id))

      assert %{
               "id" => id,
               "amount" => 43,
               "payee" => "some updated payee",
               "type" => "some updated type"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, coinbase: coinbase} do
      conn = put(conn, Routes.coinbase_path(conn, :update, coinbase), coinbase: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete coinbase" do
    setup [:create_coinbase]

    test "deletes chosen coinbase", %{conn: conn, coinbase: coinbase} do
      conn = delete(conn, Routes.coinbase_path(conn, :delete, coinbase))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.coinbase_path(conn, :show, coinbase))
      end
    end
  end

  defp create_coinbase(_) do
    coinbase = fixture(:coinbase)
    {:ok, coinbase: coinbase}
  end
end
