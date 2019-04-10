defmodule BlockchainAPIWeb.TransactionController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.{Util, Query}
  alias BlockchainAPIWeb.{
    PaymentView,
    GatewayView,
    LocationView,
    CoinbaseView,
    POCRequestView
  }
  require Logger

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, %{"block_height" => height}=params) do
    txns = Query.Transaction.at_height(height, params)

    render(conn,
      "index.json",
      transactions: txns
    )
  end

  def index(conn, params) do

    txns = Query.Transaction.list(params)

    render(conn,
      "index.json",
      transactions: txns
    )
  end

  def show(conn, %{"hash" => hash}) do
    bin_hash = hash |> Util.string_to_bin()
    case Query.Transaction.type(bin_hash) do
      "payment" ->
        payment = Query.PaymentTransaction.get!(bin_hash)
        conn
        |> put_view(PaymentView)
        |> render("show.json", payment: payment)
      "gateway" ->
        gateway = Query.GatewayTransaction.get!(bin_hash)
        conn
        |> put_view(GatewayView)
        |> render("show.json", gateway: gateway)
      "coinbase" ->
        coinbase = Query.CoinbaseTransaction.get!(bin_hash)
        conn
        |> put_view(CoinbaseView)
        |> render("show.json", coinbase: coinbase)
      "location" ->
        location = Query.LocationTransaction.get!(bin_hash)
        conn
        |> put_view(LocationView)
        |> render("show.json", location: location)
      "poc_request" ->
        poc_request = Query.POCRequestTransaction.get!(bin_hash)
        conn
        |> put_view(POCRequestView)
        |> render("show.json", poc_request: poc_request)
      _ ->
        :error
    end
  end

  def create(conn, %{"txn" => txn}) do

    case BlockchainAPI.TxnManager.submit(txn) do
      :submitted ->
        conn |> send_resp(200, "Submitted")
      :pending ->
        conn |> send_resp(200, "Pending")
      :error ->
        conn |> send_resp(200, "Error")
      :done ->
        conn |> send_resp(200, "Done")
      _ ->
        conn |> send_resp(404, "Not Found")
    end
  end
end
