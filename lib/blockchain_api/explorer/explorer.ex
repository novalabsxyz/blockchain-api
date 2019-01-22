defmodule BlockchainAPI.Explorer do
  @moduledoc """
  The Explorer context.
  """

  import Ecto.Query, warn: false
  alias BlockchainAPI.Repo

  alias BlockchainAPI.Explorer.Block
  alias BlockchainAPI.Explorer.Transaction
  alias BlockchainAPI.Explorer.PaymentTransaction
  alias BlockchainAPI.Explorer.CoinbaseTransaction
  alias BlockchainAPI.Explorer.GatewayTransaction
  alias BlockchainAPI.Explorer.LocationTransaction


  def list_transactions do
    Repo.all(Transaction)
  end

  def get_transactions!(block_height) do
    Block
    |> Repo.get!(block_height)
    |> Repo.preload([transactions: [
      :coinbase_transactions,
      :payment_transactions,
      :gateway_transactions,
      :location_transactions,
    ]])
  end

  def get_transaction!(txn_hash), do: Repo.get!(Transaction, txn_hash)

  def create_transaction(block_height, attrs \\ %{}) do
    %Transaction{block_height: block_height}
    |> Transaction.changeset(attrs)
    |> Repo.insert()
  end


  def list_blocks do
    Repo.all(Block)
  end

  def get_block!(height), do: Repo.get!(Block, height)

  def create_block(attrs \\ %{}) do
    %Block{}
    |> Block.changeset(attrs)
    |> Repo.insert()
  end

  def get_latest() do
    query = from block in Block, select: max(block.height)
    Repo.all(query)
  end

  def list_coinbase_transactions do
    Repo.all(CoinbaseTransaction)
  end

  def get_coinbase!(coinbase_hash), do: Repo.get!(CoinbaseTransaction, coinbase_hash)

  def create_coinbase(txn_hash, attrs \\ %{}) do
    %CoinbaseTransaction{coinbase_hash: txn_hash}
    |> CoinbaseTransaction.changeset(attrs)
    |> Repo.insert()
  end

  def list_payment_transactions do
    Repo.all(PaymentTransaction)
  end

  def get_payment!(payment_hash), do: Repo.get!(PaymentTransaction, payment_hash)

  def create_payment(txn_hash, attrs \\ %{}) do
    %PaymentTransaction{payment_hash: txn_hash}
    |> PaymentTransaction.changeset(attrs)
    |> Repo.insert()
  end

  def list_gateway_transactions do
    Repo.all(GatewayTransaction)
  end

  def get_gateway!(gateway_hash), do: Repo.get!(GatewayTransaction, gateway_hash)

  def create_gateway(txn_hash, attrs \\ %{}) do
    %GatewayTransaction{gateway_hash: txn_hash}
    |> GatewayTransaction.changeset(attrs)
    |> Repo.insert()
  end


  def list_location_transactions do
    Repo.all(LocationTransaction)
  end

  def get_location!(location_hash), do: Repo.get!(LocationTransaction, location_hash)

  def create_location(txn_hash, attrs \\ %{}) do
    %LocationTransaction{location_hash: txn_hash}
    |> LocationTransaction.changeset(attrs)
    |> Repo.insert()
  end
end
