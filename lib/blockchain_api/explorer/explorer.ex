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

  def get_transaction!(txn_hash), do: Repo.get!(Transaction, txn_hash)

  def create_transaction(attrs \\ %{}) do
    %Transaction{}
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

  def get_coinbase!(id), do: Repo.get!(CoinbaseTransaction, id)

  def create_coinbase(attrs \\ %{}) do
    %CoinbaseTransaction{}
    |> CoinbaseTransaction.changeset(attrs)
    |> Repo.insert()
  end

  def list_payment_transactions do
    Repo.all(PaymentTransaction)
  end

  def get_payment!(id), do: Repo.get!(PaymentTransaction, id)

  def create_payment(attrs \\ %{}) do
    %PaymentTransaction{}
    |> PaymentTransaction.changeset(attrs)
    |> Repo.insert()
  end

  def list_add_gateway_transactions do
    Repo.all(GatewayTransaction)
  end

  def get_gateway!(id), do: Repo.get!(GatewayTransaction, id)

  def create_gateway(attrs \\ %{}) do
    %GatewayTransaction{}
    |> GatewayTransaction.changeset(attrs)
    |> Repo.insert()
  end


  def list_location_transactions do
    Repo.all(LocationTransaction)
  end

  def get_location!(id), do: Repo.get!(LocationTransaction, id)

  def create_location(attrs \\ %{}) do
    %LocationTransaction{}
    |> LocationTransaction.changeset(attrs)
    |> Repo.insert()
  end
end
