defmodule BlockchainAPIWeb.PaymentControllerTest do
  use BlockchainAPIWeb.ConnCase

  alias BlockchainAPI.Explorer
  alias BlockchainAPI.Explorer.Payment

  @create_attrs %{
    amount: 42,
    fee: 42,
    nonce: 42,
    payee: "some payee",
    payer: "some payer",
    type: "some type"
  }
  @update_attrs %{
    amount: 43,
    fee: 43,
    nonce: 43,
    payee: "some updated payee",
    payer: "some updated payer",
    type: "some updated type"
  }
  @invalid_attrs %{amount: nil, fee: nil, nonce: nil, payee: nil, payer: nil, type: nil}

  def fixture(:payment) do
    {:ok, payment} = Explorer.create_payment(@create_attrs)
    payment
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all payment_transactions", %{conn: conn} do
      conn = get(conn, Routes.payment_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create payment" do
    test "renders payment when data is valid", %{conn: conn} do
      conn = post(conn, Routes.payment_path(conn, :create), payment: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.payment_path(conn, :show, id))

      assert %{
               "id" => id,
               "amount" => 42,
               "fee" => 42,
               "nonce" => 42,
               "payee" => "some payee",
               "payer" => "some payer",
               "type" => "some type"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.payment_path(conn, :create), payment: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update payment" do
    setup [:create_payment]

    test "renders payment when data is valid", %{conn: conn, payment: %Payment{id: id} = payment} do
      conn = put(conn, Routes.payment_path(conn, :update, payment), payment: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.payment_path(conn, :show, id))

      assert %{
               "id" => id,
               "amount" => 43,
               "fee" => 43,
               "nonce" => 43,
               "payee" => "some updated payee",
               "payer" => "some updated payer",
               "type" => "some updated type"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, payment: payment} do
      conn = put(conn, Routes.payment_path(conn, :update, payment), payment: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete payment" do
    setup [:create_payment]

    test "deletes chosen payment", %{conn: conn, payment: payment} do
      conn = delete(conn, Routes.payment_path(conn, :delete, payment))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.payment_path(conn, :show, payment))
      end
    end
  end

  defp create_payment(_) do
    payment = fixture(:payment)
    {:ok, payment: payment}
  end
end
