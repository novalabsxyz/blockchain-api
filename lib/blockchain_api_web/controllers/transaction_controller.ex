defmodule BlockchainAPIWeb.TransactionController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.Explorer
  require Logger
  @default_params %{page: 1, page_size: 10}

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, %{"block_height" => height}) do
    render(conn, "index.json", transactions: Explorer.get_transactions(height, @default_params))
  end
  def index(conn, %{"block_height" => height, "page" => page, "page_size" => page_size}) do
    render(conn,
      "index.json",
      transactions: Explorer.get_transactions(height,
        %{page: String.to_integer(page),
          page_size: String.to_integer(page_size)}
      )
    )
  end

  def index(conn, params) when map_size(params) == 0 do
    render(conn, "index.json", transactions: Explorer.list_transactions(@default_params))
  end
  def index(conn, params) do
    render(conn, "index.json", transactions: Explorer.list_transactions(params))
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

end
