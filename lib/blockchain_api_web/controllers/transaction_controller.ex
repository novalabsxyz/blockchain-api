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

  def create(conn, %{"txn" => txn0}) do
    txn = txn0
          |> Base.decode64!
          |> :blockchain_txn.deserialize()

    IO.puts "got txn"
    IO.inspect txn0

    IO.puts "\n"
    IO.puts "deserialized txn"
    IO.inspect txn

    is_valid = txn |> :blockchain_txn_payment_v1.is_valid()
    IO.puts "\n"
    IO.puts "is_valid?"
    IO.inspect is_valid

    IO.puts "\n"
    IO.puts "signature"
    IO.inspect :blockchain_txn_payment_v1.signature(txn)

    payer = :blockchain_txn_payment_v1.payer(txn)
    payee = :blockchain_txn_payment_v1.payee(txn)
    amount = :blockchain_txn_payment_v1.amount(txn)
    fee = :blockchain_txn_payment_v1.fee(txn)
    nonce = :blockchain_txn_payment_v1.nonce(txn)

    txn2 = :blockchain_txn_payment_v1.new(payer, payee, amount, fee, nonce)
    sig_fun = :libp2p_crypto.mk_sig_fun({:ed25519, Base.decode64!("0HmZh6t7ig7kLBTt1/wyptB5mYere4oO5CwU7df8MqbZ1cSv76+kCQbBIGJtCkxEd9tyPJB60eSm6xsoQbbyRw==")})
    txn3 = :blockchain_txn.sign(txn2, sig_fun)
    IO.puts "\n"
    IO.puts "expected txn"
    IO.inspect txn3

    IO.puts "\n"
    IO.puts "is_valid?"
    IO.inspect :blockchain_txn_payment_v1.is_valid(txn3)

    IO.puts "\n"
    IO.puts "serialized and base64 encoded txn"
    IO.inspect Base.encode64(:blockchain_txn.serialize(txn3))

    IO.puts "\n"
    IO.puts "signature"
    IO.inspect :blockchain_txn_payment_v1.signature(txn3)

    conn |> resp(201, "{}")
  end

end
