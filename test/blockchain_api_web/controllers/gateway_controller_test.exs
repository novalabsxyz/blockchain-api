defmodule BlockchainAPIWeb.GatewayControllerTest do
  use BlockchainAPIWeb.ConnCase

  alias BlockchainAPI.Explorer
  alias BlockchainAPI.Explorer.Gateway

  @create_attrs %{
    gateway: "some gateway",
    owner: "some owner",
    type: "some type"
  }
  @update_attrs %{
    gateway: "some updated gateway",
    owner: "some updated owner",
    type: "some updated type"
  }
  @invalid_attrs %{gateway: nil, owner: nil, type: nil}

  def fixture(:gateway) do
    {:ok, gateway} = Explorer.create_gateway(@create_attrs)
    gateway
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all add_gateway_transactions", %{conn: conn} do
      conn = get(conn, Routes.gateway_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create gateway" do
    test "renders gateway when data is valid", %{conn: conn} do
      conn = post(conn, Routes.gateway_path(conn, :create), gateway: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.gateway_path(conn, :show, id))

      assert %{
               "id" => id,
               "gateway" => "some gateway",
               "owner" => "some owner",
               "type" => "some type"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.gateway_path(conn, :create), gateway: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update gateway" do
    setup [:create_gateway]

    test "renders gateway when data is valid", %{conn: conn, gateway: %Gateway{id: id} = gateway} do
      conn = put(conn, Routes.gateway_path(conn, :update, gateway), gateway: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.gateway_path(conn, :show, id))

      assert %{
               "id" => id,
               "gateway" => "some updated gateway",
               "owner" => "some updated owner",
               "type" => "some updated type"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, gateway: gateway} do
      conn = put(conn, Routes.gateway_path(conn, :update, gateway), gateway: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete gateway" do
    setup [:create_gateway]

    test "deletes chosen gateway", %{conn: conn, gateway: gateway} do
      conn = delete(conn, Routes.gateway_path(conn, :delete, gateway))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.gateway_path(conn, :show, gateway))
      end
    end
  end

  defp create_gateway(_) do
    gateway = fixture(:gateway)
    {:ok, gateway: gateway}
  end
end
