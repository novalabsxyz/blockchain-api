defmodule BlockchainAPIWeb.TransactionController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.Explorer
  alias BlockchainAPI.Repo
  import Ecto.Query

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, %{"block_height" => height}) do
    block =
      Repo.one from b in Explorer.Block,
      where: b.height == ^height,
      preload: [transactions: [
        :coinbase_transactions,
        :payment_transactions,
        :gateway_transactions,
        :location_transactions
      ]]

    render(conn, "index.json", transactions: block.transactions)
  end

  def show(conn, %{"block_height" => _height, "hash" => hash}) do

    txn_type =
      Repo.one from t in Explorer.Transaction,
      where: t.hash == ^hash,
      select: t.type

    case txn_type do
      "payment" ->
        payment = Explorer.get_payment!(hash)
        conn
        |> put_view(BlockchainAPIWeb.PaymentView)
        |> render("show.json", payment: payment)
      "gateway" ->
        gateway = Explorer.get_gateway!(hash)
        conn
        |> put_view(BlockchainAPIWeb.GatewayView)
        |> render("show.json", gateway: gateway)
      "coinbase" ->
        coinbase = Explorer.get_coinbase!(hash)
        conn
        |> put_view(BlockchainAPIWeb.CoinbaseView)
        |> render("show.json", coinbase: coinbase)
      "location" ->
        location = Explorer.get_location!(hash)
        conn
        |> put_view(BlockchainAPIWeb.LocationView)
        |> render("show.json", location: location)
      _ ->
        :error
    end
  end

end
