defmodule BlockchainAPI.DBManager do
  @moduledoc false
  import Ecto.Query, warn: false
  use Timex

  alias BlockchainAPI.{Repo, Util}
  alias BlockchainAPI.Schema.{
    Block,
    Transaction,
    Account,
    AccountTransaction,
    PaymentTransaction,
    CoinbaseTransaction,
    GatewayTransaction,
    LocationTransaction,
    PendingPayment,
    PendingGateway,
    PendingLocation,
    AccountBalance
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
        fee: g.fee,
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

  def update_account!(account, attrs \\ %{}) do
    account.address
    |> get_account!()
    |> Account.changeset(attrs)
    |> Repo.update!()
  end

  def list_accounts(params) do
    Account
    |> Repo.paginate(params)
  end

  def list_all_accounts() do
    Account |> Repo.all()
  end

  def update_all_account_fee(fee) do
    Account
    |> select([:address, :fee])
    |> Repo.update_all(set: [fee: fee, updated_at: NaiveDateTime.utc_now()])
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

  def get_account_gateways(address, params \\ %{}) do
    query = from(
      at in AccountTransaction,
      where: at.account_address == ^address,
      left_join: gt in GatewayTransaction,
      on: at.account_address == gt.owner,
      where: at.txn_hash == gt.hash,
      left_join: lt in LocationTransaction,
      on: gt.gateway == lt.gateway,
      distinct: gt.gateway,
      order_by: [desc: lt.nonce],
      select: %{
        account_address: at.account_address,
        gateway: gt.gateway,
        gateway_hash: gt.hash,
        gateway_fee: gt.fee,
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

  def create_pending_gateway(attrs \\ %{}) do
    %PendingGateway{}
    |> PendingGateway.changeset(attrs)
    |> Repo.insert()
  end

  def get_pending_gateway!(hash) do
    PendingGateway
    |> where([pg], pg.hash == ^hash)
    |> Repo.one!
  end

  def update_pending_gateway!(pg, attrs \\ %{}) do
    pg.hash
    |> get_pending_gateway!()
    |> PendingGateway.changeset(attrs)
    |> Repo.update!()
  end

  def create_pending_payment(attrs \\ %{}) do
    %PendingPayment{}
    |> PendingPayment.changeset(attrs)
    |> Repo.insert()
  end

  def get_pending_payment!(hash) do
    PendingPayment
    |> where([pp], pp.hash == ^hash)
    |> Repo.one!
  end

  def update_pending_payment!(pp, attrs \\ %{}) do
    pp.hash
    |> get_pending_payment!()
    |> PendingPayment.changeset(attrs)
    |> Repo.update!()
  end

  def create_pending_location(attrs \\ %{}) do
    %PendingLocation{}
    |> PendingLocation.changeset(attrs)
    |> Repo.insert()
  end

  def get_pending_location!(hash) do
    PendingLocation
    |> where([pl], pl.hash == ^hash)
    |> Repo.one!
  end

  def update_pending_location!(pl, attrs \\ %{}) do
    pl.hash
    |> get_pending_location!()
    |> PendingLocation.changeset(attrs)
    |> Repo.update!()
  end

  def get_account_pending_gateways(address) do
    query = from(
      a in Account,
      where: a.address == ^address,
      left_join: pg in PendingGateway,
      on: pg.owner == a.address,
      order_by: [desc: pg.id],
      select: pg
    )

    query
    |> Repo.all
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&clean_pending_gateway/1)
  end

  def get_account_pending_locations(address) do
    query = from(
      a in Account,
      where: a.address == ^address,
      left_join: pl in PendingLocation,
      on: pl.owner == a.address,
      order_by: [desc: pl.nonce],
      select: pl
    )

    query
    |> Repo.all
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&clean_pending_location/1)
  end

  def get_account_pending_payments(address) do
    query = from(
      a in Account,
      where: a.address == ^address,
      left_join: pp in PendingPayment,
      on: pp.payer == a.address,
      order_by: [desc: pp.nonce],
      select: pp
    )

    query
    |> Repo.all
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&clean_pending_payment/1)
  end

  def get_account_pending_transactions(address) do
    get_account_pending_payments(address) ++
    get_account_pending_gateways(address) ++
    get_account_pending_locations(address)
  end

  def get_latest_account_balance!(address) do
    AccountBalance
    |> where([a], a.account_address == ^address)
    |> order_by([a], desc: a.block_height)
    |> limit(1)
    |> Repo.one!
  end

  def create_account_balance(attrs \\ %{}) do
    %AccountBalance{}
    |> AccountBalance.changeset(attrs)
    |> Repo.insert()
  end

  def get_account_balance_history(address) do
    %{
      day: get_account_balances_daily(address),
      week: get_account_balances_weekly(address),
      month: get_account_balances_monthly(address)
    }
  end

  #==================================================================
  # Helper functions
  #==================================================================
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
             {lat, lng} = Util.h3_to_lat_lng(map.location)
             map
             |> encoded_account_gateway_map()
             |> Map.merge(%{lat: lat, lng: lng})
           end)

    %{page | entries: data}
  end

  defp encoded_account_gateway_map(map) do
    %{map |
      account_address: Util.bin_to_string(map.account_address),
      gateway: Util.bin_to_string(map.gateway),
      gateway_hash: Util.bin_to_string(map.gateway_hash),
      location_hash: Util.bin_to_string(map.location_hash),
      owner: Util.bin_to_string(map.owner)
    }
  end

  defp clean_txn_struct(%{payment: payment, height: height, time: time}) do
    Map.merge(PaymentTransaction.encode_model(payment), %{type: "payment", height: height, time: time})
  end
  defp clean_txn_struct(%{coinbase: coinbase, height: height, time: time}) do
    Map.merge(CoinbaseTransaction.encode_model(coinbase), %{type: "coinbase", height: height, time: time})
  end
  defp clean_txn_struct(%{gateway: gateway, height: height, time: time}) do
    Map.merge(GatewayTransaction.encode_model(gateway), %{type: "gateway", height: height, time: time})
  end
  defp clean_txn_struct(%{location: location, height: height, time: time}) do
    {lat, lng} = Util.h3_to_lat_lng(location.location)
    Map.merge(LocationTransaction.encode_model(location), %{type: "location", lat: lat, lng: lng, height: height, time: time})
  end
  defp clean_txn_struct(map) when map == %{} do
    %{}
  end

  defp clean_pending_payment(nil), do: nil
  defp clean_pending_payment(%PendingPayment{}=pending_payment) do
    Map.merge(PendingPayment.encode_model(pending_payment), %{type: "payment"})
  end

  defp clean_pending_gateway(nil), do: nil
  defp clean_pending_gateway(%PendingGateway{}=pending_gateway) do
    Map.merge(PendingGateway.encode_model(pending_gateway), %{type: "gateway"})
  end

  defp clean_pending_location(nil), do: nil
  defp clean_pending_location(%PendingLocation{}=pending_location) do
    {lat, lng} = Util.h3_to_lat_lng(pending_location.location)
    Map.merge(PendingLocation.encode_model(pending_location), %{type: "location", lat: lat, lng: lng})
  end

  defp clean_transaction_page(%Scrivener.Page{entries: entries}=page) do
    clean_entries = entries |> List.flatten |> Enum.reject(&is_nil/1)
    %{page | entries: clean_entries}
  end

  defp get_account_balances_daily(address) do
    start = Timex.now() |> Timex.shift(hours: -24) |> Timex.to_unix()
    finish = Timex.now() |> Timex.to_unix()
    query_account_balance(address, start, finish)
  end

  defp get_account_balances_weekly(address) do
    start = Timex.now() |> Timex.beginning_of_week() |> Timex.to_unix()
    finish = Timex.now() |> Timex.to_unix()
    query_account_balance(address, start, finish)
  end

  defp get_account_balances_monthly(address) do
    start = Timex.now() |> Timex.beginning_of_month() |> Timex.to_unix()
    finish = Timex.now() |> Timex.to_unix()
    query_account_balance(address, start, finish)
  end

  defp query_account_balance(address, start, finish) do
    query = from(
      a in AccountBalance,
      where: a.account_address == ^address,
      where: a.block_time >= ^start,
      where: a.block_time <= ^finish,
      select: %{
        time: a.block_time,
        balance: a.balance
      }
    )

    query |> Repo.all
  end
end
