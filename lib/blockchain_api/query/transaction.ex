defmodule BlockchainAPI.Query.Transaction do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{
    Repo,
    Util,
    Schema.Block,
    Schema.Transaction,
    Schema.PaymentTransaction,
    Schema.CoinbaseTransaction,
    Schema.GatewayTransaction,
    Schema.LocationTransaction
  }

  def list(_params) do
    query = from(
      transaction in Transaction,
      left_join: block in Block,
      on: transaction.block_height == block.height,
      left_join: coinbase_transaction in CoinbaseTransaction,
      on: transaction.hash == coinbase_transaction.hash,
      left_join: payment_transaction in PaymentTransaction,
      on: transaction.hash == payment_transaction.hash,
      left_join: gateway_transaction in GatewayTransaction,
      on: transaction.hash == gateway_transaction.hash,
      left_join: location_transaction in LocationTransaction,
      on: transaction.hash == location_transaction.hash,
      order_by: [desc: block.height, desc: transaction.id],
      select: [
        coinbase_transaction,
        payment_transaction,
        gateway_transaction,
        location_transaction
      ])

    query
    |> Repo.all()
    |> format_transactions()

  end

  def at_height(block_height, params) do
    query = from(
      block in Block,
      where: block.height == ^block_height,
      left_join: transaction in Transaction,
      on: block.height == transaction.block_height,
      left_join: coinbase_transaction in CoinbaseTransaction,
      on: transaction.hash == coinbase_transaction.hash,
      left_join: payment_transaction in PaymentTransaction,
      on: transaction.hash == payment_transaction.hash,
      left_join: gateway_transaction in GatewayTransaction,
      on: transaction.hash == gateway_transaction.hash,
      left_join: location_transaction in LocationTransaction,
      on: transaction.hash == location_transaction.hash,
      order_by: [
        desc: block.height,
        desc: transaction.id,
        desc: payment_transaction.nonce,
        desc: location_transaction.nonce
      ],
      select: %{
        time: block.time,
        height: block.height,
        coinbase: coinbase_transaction,
        payment: payment_transaction,
        gateway: gateway_transaction,
        location: location_transaction
      })

    query
    |> Repo.all()
    |> format_blocks()
  end

  def type(hash) do
    Repo.one from t in Transaction,
      where: t.hash == ^hash,
      select: t.type
  end

  def get!(txn_hash) do
    Transaction
    |> where([t], t.hash == ^txn_hash)
    |> Repo.one!
  end

  def create(block_height, attrs \\ %{}) do
    %Transaction{block_height: block_height}
    |> Transaction.changeset(attrs)
    |> Repo.insert()
  end

  #==================================================================
  # Helper functions
  #==================================================================
  defp format_transactions(entries) do
    entries
    |> List.flatten
    |> Enum.reject(&is_nil/1)
  end

  defp format_blocks(entries) do
    entries
    |> Enum.map(fn map -> :maps.filter(fn _, v -> v != nil end, map) end)
    |> Enum.reduce([], fn map, acc -> [Util.clean_txn_struct(map) | acc] end)
    |> Enum.reject(&is_nil/1)
    |> Enum.reverse
  end
end
