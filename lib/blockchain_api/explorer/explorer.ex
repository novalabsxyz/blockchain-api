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
    LocationTransaction,
    PendingTransaction
  }

  def list_transactions(params) do
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
      order_by: [desc: block.height],
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
      on: transaction.hash == coinbase_transaction.hash,
      left_join: payment_transaction in PaymentTransaction,
      on: transaction.hash == payment_transaction.hash,
      left_join: gateway_transaction in GatewayTransaction,
      on: transaction.hash == gateway_transaction.hash,
      left_join: location_transaction in LocationTransaction,
      on: transaction.hash == location_transaction.hash,
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
    |> order_by([b], desc: b.height)
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

  def get_latest_block() do
    query = from block in Block, select: max(block.height)
    Repo.all(query)
  end

  def list_coinbase_transactions(params) do
    CoinbaseTransaction
    |> Repo.paginate(params)
  end

  def get_coinbase!(hash) do
    CoinbaseTransaction
    |> where([ct], ct.hash == ^hash)
    |> Repo.one!
  end

  def create_coinbase(txn_hash, attrs \\ %{}) do
    %CoinbaseTransaction{hash: txn_hash}
    |> CoinbaseTransaction.changeset(attrs)
    |> Repo.insert()
  end

  def list_payment_transactions(params) do
    PaymentTransaction
    |> Repo.paginate(params)
  end

  def get_payment!(hash) do
    PaymentTransaction
    |> where([pt], pt.hash == ^hash)
    |> Repo.one!
  end

  def create_payment(txn_hash, attrs \\ %{}) do
    %PaymentTransaction{hash: txn_hash}
    |> PaymentTransaction.changeset(attrs)
    |> Repo.insert()
  end

  def list_gateway_transactions(params) do

    query = from(
      g in GatewayTransaction,
      left_join: l in LocationTransaction,
      on: g.gateway == l.gateway,
      select: %{
        gateway: g.gateway,
        gateway_hash: g.hash,
        owner: g.owner,
        location: l.location,
        location_fee: l.fee,
        location_nonce: l.nonce,
        location_hash: l.hash
      }
    )

    query
    |> Repo.paginate(params)
  end

  def get_gateway!(hash) do
    GatewayTransaction
    |> where([gt], gt.hash == ^hash)
    |> Repo.one!
  end

  def create_gateway(txn_hash, attrs \\ %{}) do
    %GatewayTransaction{hash: txn_hash}
    |> GatewayTransaction.changeset(attrs)
    |> Repo.insert()
  end

  def list_location_transactions(params) do
    LocationTransaction
    |> Repo.paginate(params)
  end

  def get_location!(hash) do
    LocationTransaction
    |> where([lt], lt.hash == ^hash)
    |> Repo.one!
  end

  def create_location(txn_hash, attrs \\ %{}) do
    %LocationTransaction{hash: txn_hash}
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

  def list_all_accounts() do
    Account |> Repo.all()
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
      order_by: [desc: block.height],
      select: %{
        time: block.time,
        height: transaction.block_height,
        coinbase: coinbase_transaction,
        payment: payment_transaction,
        gateway: gateway_transaction,
        location: location_transaction
      }
    )

    query
    |> Repo.paginate(params)
    |> clean_account_transactions()

  end

  def create_pending_transaction(attrs \\ %{}) do
    %PendingTransaction{}
    |> PendingTransaction.changeset(attrs)
    |> Repo.insert()
  end

  def list_pending_transactions(params) do
    PendingTransaction
    |> order_by([pt], desc: pt.inserted_at)
    |> Repo.paginate(params)
  end

  def get_pending_transaction!(hash) do
    PendingTransaction
    |> where([pt], pt.hash == ^hash)
    |> Repo.one!
  end

  def get_pending_transaction(hash) do
    PendingTransaction
    |> where([pt], pt.hash == ^hash)
    |> Repo.one
  end

  def update_pending_transaction(txn, attrs \\ %{}) do
    txn.hash
    |> get_pending_transaction!()
    |> PendingTransaction.changeset(attrs)
    |> Repo.update()
  end

  def get_account_gateways(address, params \\ %{}) do
    query = from(
      at in AccountTransaction,
      where: at.account_address == ^address,
      left_join: gt in GatewayTransaction,
      on: at.account_address == gt.owner,
      where: at.txn_hash == gt.hash,
      left_join: lt in LocationTransaction,
      on: gt.gateway == lt.gateway,
      select: %{
        account_address: at.account_address,
        gateway: gt.gateway,
        gateway_hash: gt.hash,
        owner: gt.owner,
        location: lt.location,
        location_fee: lt.fee,
        location_nonce: lt.nonce,
        location_hash: lt.hash
      })

    query
    |> Repo.paginate(params)
    |> clean_account_gateways()
  end

  ## Helper functions

  defp clean_account_transactions(%Scrivener.Page{entries: entries}=page) do
    data = entries
           |> Enum.map(fn map -> :maps.filter(fn _, v -> v != nil end, map) end)
           |> Enum.reduce([], fn map, acc -> [clean_txn_struct(map) | acc] end)
           |> Enum.reverse

    %{page | entries: data}
  end

  defp clean_account_gateways(%Scrivener.Page{entries: entries}=page) do
    data = entries
           |> Enum.map(fn map ->
             {lat, long} =
               case map.location do
                 nil -> {nil, nil}
                 loc -> :h3.to_geo(loc)
               end
               Map.merge(Map.drop(map, [:location]), %{lat: lat, lng: long})
           end)

    %{page | entries: data}
  end

  defp clean_txn_struct(%{payment: payment, height: height, time: time}) do
    Map.merge(Map.drop(Map.from_struct(payment), [:__meta__, :transaction]), %{type: "payment", height: height, time: time})
  end
  defp clean_txn_struct(%{coinbase: coinbase, height: height, time: time}) do
    Map.merge(Map.drop(Map.from_struct(coinbase), [:__meta__, :transaction]), %{type: "coinbase", height: height, time: time})
  end
  defp clean_txn_struct(%{gateway: gateway, height: height, time: time}) do
    Map.merge(Map.drop(Map.from_struct(gateway), [:__meta__, :transaction]), %{type: "gateway", height: height, time: time})
  end
  defp clean_txn_struct(%{location: location, height: height, time: time}) do
    Map.merge(Map.drop(Map.from_struct(location), [:__meta__, :transaction]), %{type: "location", height: height, time: time})
  end

  defp clean_transaction_page(%Scrivener.Page{entries: entries}=page) do
    clean_entries = entries |> List.flatten |> Enum.reject(&is_nil/1)
    %{page | entries: clean_entries}
  end

end
