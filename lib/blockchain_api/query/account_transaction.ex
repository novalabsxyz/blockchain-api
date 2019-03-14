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
    Schema.LocationTransaction
  }

  def create(attrs \\ %{}) do
    %AccountTransaction{}
    |> AccountTransaction.changeset(attrs)
    |> Repo.insert()
  end

  def get(address, params) do
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
      order_by: [
        desc: block.height,
        desc: transaction.id,
        desc: payment_transaction.nonce,
        desc: location_transaction.nonce
      ],
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

  def get_gateways(address, params \\ %{}) do
    query = from(
      at in AccountTransaction,
      where: at.account_address == ^address,
      left_join: gt in GatewayTransaction,
      on: at.account_address == gt.owner,
      where: at.txn_hash == gt.hash,
      left_join: lt in LocationTransaction,
      on: gt.gateway == lt.gateway,
      distinct: gt.gateway,
      order_by: [desc: gt.id, desc: lt.nonce],
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
end
