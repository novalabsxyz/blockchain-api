defmodule BlockchainAPIWeb.PaymentController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.{Util, Query}
  import BlockchainAPI.Cache.CacheService

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, params) do
    txns = Query.PaymentTransaction.list(params)

    conn
    |> put_cache_headers(ttl: :short, key: "block")
    |> render("index.json", payment_transactions: txns)
  end

  def show(conn, %{"hash" => hash}) do
    payment =
      hash
      |> Util.string_to_bin()
      |> Query.PaymentTransaction.get!()

    conn
    |> put_cache_headers(ttl: :long, key: "eternal")
    |> render("show.json", payment: payment)
  end
end
