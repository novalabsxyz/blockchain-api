defmodule BlockchainAPI.Query.AccountTransaction do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{
    Repo,
    Util,
    Schema.Block,
    Schema.AccountTransaction,
    Schema.Transaction,
    Schema.PaymentTransaction,
    Schema.CoinbaseTransaction,
    Schema.GatewayTransaction,
    Schema.LocationTransaction,
    Schema.Hotspot,
    Schema.Account,
    Schema.PendingLocation,
    Schema.PendingGateway,
    Schema.PendingPayment,
    Schema.PendingCoinbase
  }

  def create(attrs \\ %{}) do
    %AccountTransaction{}
    |> AccountTransaction.changeset(attrs)
    |> Repo.insert()
  end

  def get_pending(address) do
    from(
      a in Account,
      where: a.address == ^address,
      left_join: pg in PendingGateway,
      on: pg.owner == a.address,
      left_join: pp in PendingPayment,
      on: pp.payer == a.address or pp.payee == a.address,
      left_join: pl in PendingLocation,
      on: pl.owner == a.address,
      left_join: cb in PendingCoinbase,
      on: a.address == cb.payee,
      select: %{
        time: fragment("SELECT MAX(time) FROM blocks"),
        height: fragment("SELECT MAX(block_height) FROM transactions"),
        coinbase: cb,
        payment: pp,
        gateway: pg,
        location: pl
      }
    )
  end

  def get_cleared(address) do
    from(
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
      select: %{
        time: block.time,
        height: transaction.block_height,
        coinbase: coinbase_transaction,
        payment: payment_transaction,
        gateway: gateway_transaction,
        location: location_transaction
      }
    )
  end

  def get(address, params) do

    pending = get_pending(address)
    cleared = get_cleared(address)

    pending
    |> Ecto.Query.union(^cleared)
    |> Repo.all()
    |> clean_account_transactions()
  end

  def get_gateways(address, params \\ %{}) do
    query = from(
      at in AccountTransaction,
      where: at.account_address == ^address,
      left_join: gt in GatewayTransaction,
      on: at.account_address == gt.owner,
      left_join: hotspot in Hotspot,
      on: at.account_address == hotspot.owner,
      where: gt.gateway == hotspot.address,
      where: gt.owner == hotspot.owner,
      where: at.txn_hash == gt.hash,
      left_join: lt in LocationTransaction,
      on: gt.gateway == lt.gateway,
      distinct: hotspot.address,
      order_by: [desc: lt.nonce, desc: hotspot.id],
      select: %{
        account_address: at.account_address,
        gateway: gt.gateway,
        gateway_hash: gt.hash,
        gateway_fee: gt.fee,
        owner: gt.owner,
        location: lt.location,
        location_fee: lt.fee,
        location_nonce: lt.nonce,
        location_hash: lt.hash,
        long_city: hotspot.long_city,
        long_street: hotspot.long_street,
        long_state: hotspot.long_state,
        long_country: hotspot.long_country,
        short_city: hotspot.short_city,
        short_street: hotspot.short_street,
        short_state: hotspot.short_state,
        short_country: hotspot.short_country,
      })

    query
    |> Repo.all()
    |> clean_account_gateways()
  end

  #==================================================================
  # Helper functions
  #==================================================================
  defp clean_account_transactions(entries) do
    entries
    |> Enum.map(fn map -> :maps.filter(fn _, v -> v != nil end, map) end)
    |> Enum.reduce([], fn map, acc -> [Util.clean_txn_struct(map) | acc] end)
    |> Enum.reverse
  end

  defp clean_account_gateways(entries) do
    entries
    |> Enum.map(fn map ->
      {lat, lng} = Util.h3_to_lat_lng(map.location)
      map
      |> encoded_account_gateway_map()
      |> Map.merge(%{lat: lat, lng: lng})
    end)
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
end
