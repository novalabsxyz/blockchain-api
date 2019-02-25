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
    bin_hash = hash |> Util.string_to_bin()
    case Explorer.get_transaction_type(bin_hash) do
      "payment" ->
        payment = Explorer.get_payment!(bin_hash)
        conn
        |> put_view(BlockchainAPIWeb.PaymentView)
        |> render("show.json", payment: payment)
      "gateway" ->
        gateway = Explorer.get_gateway!(bin_hash)
        conn
        |> put_view(BlockchainAPIWeb.GatewayView)
        |> render("show.json", gateway: gateway)
      "coinbase" ->
        coinbase = Explorer.get_coinbase!(bin_hash)
        conn
        |> put_view(BlockchainAPIWeb.CoinbaseView)
        |> render("show.json", coinbase: coinbase)
      "location" ->
        location = Explorer.get_location!(bin_hash)
        conn
        |> put_view(BlockchainAPIWeb.LocationView)
        |> render("show.json", location: location)
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
