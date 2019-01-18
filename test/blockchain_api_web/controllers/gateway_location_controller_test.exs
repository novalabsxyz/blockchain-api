defmodule BlockchainAPIWeb.GatewayLocationControllerTest do
  use BlockchainAPIWeb.ConnCase

  alias BlockchainAPI.Explorer
  alias BlockchainAPI.Explorer.GatewayLocation

  @create_attrs %{
    fee: 42,
    gateway: "some gateway",
    location: "some location",
    nonce: 42,
    owner: "some owner",
    type: "some type"
  }
  @update_attrs %{
    fee: 43,
    gateway: "some updated gateway",
    location: "some updated location",
    nonce: 43,
    owner: "some updated owner",
    type: "some updated type"
  }
  @invalid_attrs %{fee: nil, gateway: nil, location: nil, nonce: nil, owner: nil, type: nil}

  def fixture(:gateway_location) do
    {:ok, gateway_location} = Explorer.create_gateway_location(@create_attrs)
    gateway_location
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all assert_location_transactions", %{conn: conn} do
      conn = get(conn, Routes.gateway_location_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create gateway_location" do
    test "renders gateway_location when data is valid", %{conn: conn} do
      conn = post(conn, Routes.gateway_location_path(conn, :create), gateway_location: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.gateway_location_path(conn, :show, id))

      assert %{
               "id" => id,
               "fee" => 42,
               "gateway" => "some gateway",
               "location" => "some location",
               "nonce" => 42,
               "owner" => "some owner",
               "type" => "some type"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.gateway_location_path(conn, :create), gateway_location: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update gateway_location" do
    setup [:create_gateway_location]

    test "renders gateway_location when data is valid", %{conn: conn, gateway_location: %GatewayLocation{id: id} = gateway_location} do
      conn = put(conn, Routes.gateway_location_path(conn, :update, gateway_location), gateway_location: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.gateway_location_path(conn, :show, id))

      assert %{
               "id" => id,
               "fee" => 43,
               "gateway" => "some updated gateway",
               "location" => "some updated location",
               "nonce" => 43,
               "owner" => "some updated owner",
               "type" => "some updated type"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, gateway_location: gateway_location} do
      conn = put(conn, Routes.gateway_location_path(conn, :update, gateway_location), gateway_location: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete gateway_location" do
    setup [:create_gateway_location]

    test "deletes chosen gateway_location", %{conn: conn, gateway_location: gateway_location} do
      conn = delete(conn, Routes.gateway_location_path(conn, :delete, gateway_location))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.gateway_location_path(conn, :show, gateway_location))
      end
    end
  end

  defp create_gateway_location(_) do
    gateway_location = fixture(:gateway_location)
    {:ok, gateway_location: gateway_location}
  end
end
