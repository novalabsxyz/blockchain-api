defmodule BlockchainAPIWeb.TransactionController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.Explorer
  require Logger

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, %{"block_height" => height, "page" => page, "page_size" => page_size}) do
    page = Explorer.get_transactions(height, %{page: String.to_integer(page), page_size: String.to_integer(page_size)})

    render(conn,
      "index.json",
      transactions: page.entries,
      page_number: page.page_number,
      page_size: page.page_size,
      total_pages: page.total_pages,
      total_entries: page.total_entries
    )
  end

  def index(conn, params) do

    page = Explorer.list_transactions(params)

    render(conn,
      "index.json",
      transactions: page.entries,
      page_number: page.page_number,
      page_size: page.page_size,
      total_pages: page.total_pages,
      total_entries: page.total_entries
    )
  end

  def show(conn, %{"hash" => hash}) do
    case Explorer.get_transaction_type(hash) do
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

  def create(conn, %{"txn" => txn}) do

    case BlockchainAPI.TxnManager.submit(txn) do
      :ok ->
        conn |> send_resp(200, "ok")
      _ ->
        conn |> send_resp(201, "error")
    end
  end

end
