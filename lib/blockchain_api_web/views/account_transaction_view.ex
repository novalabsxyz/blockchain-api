defmodule BlockchainAPIWeb.AccountTransactionView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.AccountTransactionView
  alias BlockchainAPI.Explorer.CoinbaseTransaction
  alias BlockchainAPI.Explorer.PaymentTransaction
  alias BlockchainAPI.Explorer.GatewayTransaction
  alias BlockchainAPI.Explorer.LocationTransaction

  def render("index.json", %{account_transactions: account_transactions}) do
    %{data: render_many(account_transactions, AccountTransactionView, "account_transaction.json")}
  end

  def render("show.json", %{account_transaction: account_transaction}) do
    %{data: render_one(account_transaction, AccountTransactionView, "account_transaction.json")}
  end

  def render("account_transaction.json", %{account_transaction: %CoinbaseTransaction{}=coinbase}) do
    %{coinbase_hash: coinbase.coinbase_hash,
      amount: coinbase.amount,
      payee: coinbase.payee}
  end

  def render("account_transaction.json", %{account_transaction: %LocationTransaction{}=location}) do
    %{location_hash: location.location_hash,
      gateway: location.gateway,
      owner: location.owner,
      location: location.location,
      nonce: location.nonce,
      fee: location.fee}
  end

  def render("account_transaction.json", %{account_transaction: %GatewayTransaction{}=gateway}) do
    %{gateway_hash: gateway.gateway_hash,
      owner: gateway.owner,
      gateway: gateway.gateway}
  end

  def render("account_transaction.json", %{account_transaction: %PaymentTransaction{}=payment}) do
    %{payment_hash: payment.payment_hash,
      amount: payment.amount,
      payee: payment.payee,
      payer: payment.payer,
      fee: payment.fee,
      nonce: payment.nonce}
  end
end
