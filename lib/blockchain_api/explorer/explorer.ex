defmodule BlockchainAPI.Explorer do
  @moduledoc """
  The Explorer context.
  """

  import Ecto.Query, warn: false
  alias BlockchainAPI.Repo

  alias BlockchainAPI.Explorer.Block
  alias BlockchainAPI.Explorer.{
    Transaction,
    Account,
    AccountTransaction,
    PaymentTransaction,
    CoinbaseTransaction,
    GatewayTransaction,
    LocationTransaction
  }

  def list_transactions(params) do
    query = from(
      transaction in Transaction,
      left_join: coinbase_transaction in CoinbaseTransaction,
      on: transaction.hash == coinbase_transaction.coinbase_hash,
      left_join: payment_transaction in PaymentTransaction,
      on: transaction.hash == payment_transaction.payment_hash,
      left_join: gateway_transaction in GatewayTransaction,
      on: transaction.hash == gateway_transaction.gateway_hash,
      left_join: location_transaction in LocationTransaction,
      on: transaction.hash == location_transaction.location_hash,
      select: [
        coinbase_transaction,
        payment_transaction,
        gateway_transaction,
        location_transaction
      ])

    query
    |> Repo.paginate(params)
    |> clean_transaction_page()

  end

  def get_transactions(block_height, params) do
    query = from(
      transaction in Transaction,
      where: transaction.block_height == ^block_height,
      left_join: coinbase_transaction in CoinbaseTransaction,
      on: transaction.hash == coinbase_transaction.coinbase_hash,
      left_join: payment_transaction in PaymentTransaction,
      on: transaction.hash == payment_transaction.payment_hash,
      left_join: gateway_transaction in GatewayTransaction,
      on: transaction.hash == gateway_transaction.gateway_hash,
      left_join: location_transaction in LocationTransaction,
      on: transaction.hash == location_transaction.location_hash,
      select: [
        coinbase_transaction,
        payment_transaction,
        gateway_transaction,
        location_transaction
      ])

    query
    |> Repo.paginate(params)
    |> clean_transaction_page()
  end

  def get_transaction_type(hash) do
    Repo.one from t in Transaction,
      where: t.hash == ^hash,
      select: t.type
  end

  def get_transaction!(txn_hash) do
    Transaction
    |> where([t], t.hash == ^txn_hash)
    |> Repo.one!
  end

  def create_transaction(block_height, attrs \\ %{}) do
    %Transaction{block_height: block_height}
    |> Transaction.changeset(attrs)
    |> Repo.insert()
  end

  def list_blocks(params) do
    Block
    |> Repo.paginate(params)
  end

  def get_block!(height) do
    Block
    |> where([b], b.height == ^height)
    |> Repo.one!
  end

  def create_block(attrs \\ %{}) do
    %Block{}
    |> Block.changeset(attrs)
    |> Repo.insert()
  end

  def get_latest() do
    query = from block in Block, select: max(block.height)
    Repo.all(query)
  end

  def list_coinbase_transactions(params) do
    CoinbaseTransaction
    |> Repo.paginate(params)
  end

  def get_coinbase!(coinbase_hash) do
    CoinbaseTransaction
    |> where([ct], ct.coinbase_hash == ^coinbase_hash)
    |> Repo.one!
  end

  def create_coinbase(txn_hash, attrs \\ %{}) do
    %CoinbaseTransaction{coinbase_hash: txn_hash}
    |> CoinbaseTransaction.changeset(attrs)
    |> Repo.insert()
  end

  def list_payment_transactions(params) do
    PaymentTransaction
    |> Repo.paginate(params)
  end

  def get_payment!(payment_hash) do
    PaymentTransaction
    |> where([pt], pt.payment_hash == ^payment_hash)
    |> Repo.one!
  end

  def create_payment(txn_hash, attrs \\ %{}) do
    %PaymentTransaction{payment_hash: txn_hash}
    |> PaymentTransaction.changeset(attrs)
    |> Repo.insert()
  end

  def list_gateway_transactions(params) do
    GatewayTransaction
    |> Repo.paginate(params)
  end

  def get_gateway!(gateway_hash) do
    GatewayTransaction
    |> where([gt], gt.gateway_hash == ^gateway_hash)
    |> Repo.one!
  end

  def create_gateway(txn_hash, attrs \\ %{}) do
    %GatewayTransaction{gateway_hash: txn_hash}
    |> GatewayTransaction.changeset(attrs)
    |> Repo.insert()
  end

  def list_location_transactions(params) do
    LocationTransaction
    |> Repo.paginate(params)
  end

  def get_location!(location_hash) do
    LocationTransaction
    |> where([lt], lt.location_hash == ^location_hash)
    |> Repo.one!
  end

  def create_location(txn_hash, attrs \\ %{}) do
    %LocationTransaction{location_hash: txn_hash}
    |> LocationTransaction.changeset(attrs)
    |> Repo.insert()
  end

  def create_account(attrs \\ %{}) do
    %Account{}
    |> Account.changeset(attrs)
    |> Repo.insert()
  end

  def get_account!(address) do
    Account
    |> where([a], a.address == ^address)
    |> Repo.one!
  end

  def update_account(account, attrs \\ %{}) do
    account.address
    |> get_account!()
    |> Account.changeset(attrs)
    |> Repo.update()
  end

  def list_accounts(params) do
    Account
    |> Repo.paginate(params)
  end

  def create_account_transaction(attrs \\ %{}) do
    %AccountTransaction{}
    |> AccountTransaction.changeset(attrs)
    |> Repo.insert()
  end

  def get_account_transactions(address, params) do
    query = from(
      at in AccountTransaction,
      where: at.account_address == ^address,
      left_join: transaction in Transaction,
      on: at.txn_hash == transaction.hash,
      left_join: coinbase_transaction in CoinbaseTransaction,
      on: transaction.hash == coinbase_transaction.coinbase_hash,
      left_join: payment_transaction in PaymentTransaction,
      on: transaction.hash == payment_transaction.payment_hash,
      left_join: gateway_transaction in GatewayTransaction,
      on: transaction.hash == gateway_transaction.gateway_hash,
      left_join: location_transaction in LocationTransaction,
      on: transaction.hash == location_transaction.location_hash,
      select: [
        coinbase_transaction,
        payment_transaction,
        gateway_transaction,
        location_transaction
      ]
    )

    query
    |> Repo.paginate(params)
    |> clean_transaction_page()

  end

  defp clean_transaction_page(%Scrivener.Page{entries: entries}=page) do
    clean_entries = entries |> List.flatten |> Enum.reject(&is_nil/1)
    %{page | entries: clean_entries}
  end

end
