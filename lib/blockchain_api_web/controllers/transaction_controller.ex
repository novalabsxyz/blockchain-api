defmodule BlockchainAPIWeb.TransactionController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.{Util, Query, Schema}
  alias BlockchainAPIWeb.{
    PaymentView,
    GatewayView,
    LocationView,
    CoinbaseView,
    POCRequestView,
    POCReceiptsView,
    SecurityView,
    ElectionView
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
      "security" ->
        security = Query.SecurityTransaction.get!(bin_hash)
        conn
        |> put_view(SecurityView)
        |> render("show.json", security: security)
      "election" ->
        election = Query.ElectionTransaction.get!(bin_hash)
        conn
        |> put_view(ElectionView)
        |> render("show.json", election: election)
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
      "poc_receipts" ->
        poc_receipts = Query.POCReceiptsTransaction.get!(bin_hash)
        conn
        |> put_view(POCReceiptsView)
        |> render("show.json", poc_receipts: poc_receipts)
      _ ->
        :error
    end
  end

  def create(conn, %{"txn" => txn0}) do

    txn = txn0
          |> Base.decode64!()
          |> :blockchain_txn.deserialize()

    case :blockchain_txn.type(txn) do
      :blockchain_txn_payment_v1 ->
        Schema.PendingPayment.map(txn) |> Query.PendingPayment.create()
      _ ->
        :ok
    end

    send_resp(conn, 200, "ok")

  end
end
