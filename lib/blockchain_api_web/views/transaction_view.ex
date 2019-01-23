defmodule BlockchainAPIWeb.TransactionView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.TransactionView

  def render("index.json", %{transactions: transactions}) do
    %{data: render_many(transactions, TransactionView, "transaction.json")}
  end

  def render("show.json", %{transaction: transaction}) do
    %{data: render_one(transaction, TransactionView, "transaction.json")}
  end

  def render("transaction.json", %{transaction: transaction}) do

    data =
      case transaction.type do
        "coinbase" ->
          [coinbase] = transaction.coinbase_transactions
          %{coinbase_hash: coinbase.coinbase_hash,
            amount: coinbase.amount,
            payee: coinbase.payee}
        "payment" ->
          [payment] = transaction.payment_transactions
          %{payment_hash: payment.payment_hash,
            amount: payment.amount,
            payee: payment.payee,
            payer: payment.payer,
            fee: payment.fee,
            nonce: payment.nonce}
        "gateway" ->
          [gateway] = transaction.gateway_transactions
          %{hash: gateway.hash,
            type: gateway.type,
            owner: gateway.owner,
            gateway: gateway.gateway}
        "location" ->
          [location] = transaction.location_transactions
          %{location_hash: location.gateway_hash,
            gateway: location.gateway,
            owner: location.owner,
            location: location.location,
            nonce: location.nonce,
            fee: location.fee}
      end

    %{block_height: transaction.block_height,
      type: transaction.type,
      data: data}
  end
end
