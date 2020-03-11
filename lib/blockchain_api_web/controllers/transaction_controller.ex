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
    DataCreditView,
    ElectionView,
    RewardsView,
    OUIView,
    SecExchangeView,
    PaymentV2View,
    StateChannelOpenView,
    StateChannelCloseView
  }

  import BlockchainAPI.Cache.CacheService

  require Logger

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, %{"block_height" => height} = _params) do
    txns = Query.Transaction.get(height)

    conn
    |> put_cache_headers(ttl: :long, key: "eternal")
    |> render("index.json", transactions: txns)
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

      "data_credit" ->
        data_credit = Query.DataCreditTransaction.get!(bin_hash)

        conn
        |> put_view(DataCreditView)
        |> render("show.json", data_credit: data_credit)

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
        poc_receipts = Query.POCReceiptsTransaction.get(bin_hash)

        conn
        |> put_view(POCReceiptsView)
        |> render("show.json", poc_receipts: poc_receipts)

      "rewards" ->
        rewards = Query.RewardsTransaction.get!(bin_hash)

        conn
        |> put_view(RewardsView)
        |> render("show.json", rewards: rewards)

      "oui" ->
        oui = Query.OUITransaction.get!(bin_hash)

        conn
        |> put_view(OUIView)
        |> render("show.json", oui: oui)

      "security_exchange" ->
        sec_exchange = Query.SecurityExchangeTransaction.get!(bin_hash)

        conn
        |> put_view(SecExchangeView)
        |> render("show.json", sec_exchange: sec_exchange)

      "payment_v2" ->
        payment_v2 = Query.PaymentV2Txn.get!(bin_hash)

        conn
        |> put_view(PaymentV2View)
        |> render("show.json", payment_v2: payment_v2)

      "sc_open" ->
        sc_open = Query.StateChannelOpenTxn.get!(bin_hash)

        conn
        |> put_view(StateChannelOpenView)
        |> render("show.json", sc_open: sc_open)

      "sc_close" ->
        sc_close = Query.StateChannelCloseTxn.get!(bin_hash)

        conn
        |> put_view(StateChannelCloseView)
        |> render("show.json", sc_close: sc_close)

      _ ->
        :error
    end
  end

  def create(conn, %{"txn" => txn0}) do
    txn =
      txn0
      |> Base.decode64!()
      |> :blockchain_txn.deserialize()

    chain = :blockchain_worker.blockchain()

    case :blockchain.height(chain) do
      {:error, _} ->
        send_resp(conn, 404, "no_chain")

      {:ok, chain_height} ->
        case :blockchain_txn.type(txn) do
          :blockchain_txn_payment_v1 ->
            Schema.PendingPayment.map(txn, chain_height) |> Query.PendingPayment.create()

          :blockchain_txn_add_gateway_v1 ->
            # Check that the account exists in the DB
            owner = :blockchain_txn_add_gateway_v1.owner(txn)

            case Query.Account.get(owner) do
              nil ->
                # Create account
                ledger = :blockchain.ledger(chain)
                {:ok, fee} = :blockchain_ledger_v1.transaction_fee(ledger)

                case Query.Account.create(%{balance: 0, address: owner, nonce: 0, fee: fee}) do
                  {:ok, _} ->
                    Schema.PendingGateway.map(txn, chain_height) |> Query.PendingGateway.create()

                  {:error, _} ->
                    send_resp(conn, 404, "error_adding_gateway_owner")
                end

              _account ->
                Schema.PendingGateway.map(txn, chain_height) |> Query.PendingGateway.create()
            end

          :blockchain_txn_assert_location_v1 ->
            Schema.PendingLocation.map(txn, chain_height) |> Query.PendingLocation.create()

          :blockchain_txn_coinbase_v1 ->
            Schema.PendingCoinbase.map(txn, chain_height) |> Query.PendingCoinbase.create()

          :blockchain_txn_oui_v1 ->
            Schema.PendingOUI.map(txn, chain_height)
            |> Query.PendingOUI.create()

          :blockchain_txn_security_exchange_v1 ->
            Schema.PendingSecExchange.map(txn, chain_height) |> Query.PendingSecExchange.create()

          _ ->
            :ok
        end

        send_resp(conn, 200, "ok")
    end
  end
end
