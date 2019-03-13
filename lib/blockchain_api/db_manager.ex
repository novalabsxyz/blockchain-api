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
    AccountBalance,
    Hotspot
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
    |> clean_gateways()
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
    account
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
    pg
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
    pp
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
    pl
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
      day: sample_daily_account_balance(address),
      week: sample_weekly_account_balance(address),
      month: sample_monthly_account_balance(address)
    }
  end

  def list_hotspots(params) do
    Hotspot |> Repo.paginate(params)
  end

  def get_hotspot!(hotspot) do
    Hotspot
    |> where([h], h.gateway == ^hotspot)
    |> Repo.one!
  end

  def create_hotspot(attrs \\ %{}) do
    %Hotspot{}
    |> Hotspot.changeset(attrs)
    |> Repo.insert()
  end

  def update_hotspot!(hotspot, attrs \\ %{}) do
    hotspot
    |> Hotspot.changeset(attrs)
    |> Repo.update!()
  end

  def get_payer_speculative_nonce(address) do
    query_pending_nonce = from(
      pp in PendingPayment,
      where: pp.payer == ^address,
      where: pp.status != "error",
      select: pp.nonce,
      order_by: [desc: pp.id],
      limit: 1
    )

    query_account_nonce = from(
      a in Account,
      where: a.address == ^address,
      select: a.nonce,
      order_by: [desc: a.id],
      limit: 1
    )

    pending_nonce = Repo.one(query_pending_nonce)
    account_nonce = Repo.one(query_account_nonce)
    case {pending_nonce, account_nonce} do
      {nil, nil} ->
        # there is neither a pending_nonce nor an account_nonce
        0
      {nil, account_nonce} ->
        # there is no pending_nonce but an account_nonce
        account_nonce
      {pending_nonce, nil} ->
        # this shouldn't be possible _ideally_
        pending_nonce
      {pending_nonce, account_nonce} ->
        # return the max of pending_nonce, account_nonce
        max(pending_nonce, account_nonce)
    end
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

  defp clean_gateways(%Scrivener.Page{entries: entries}=page) do
    data = entries
           |> Enum.map(fn map ->
             {lat, lng} = Util.h3_to_lat_lng(map.location)
             map
             |> encoded_gateway_map()
             |> Map.merge(%{lat: lat, lng: lng})
           end)

    %{page | entries: data}
  end

  defp encoded_gateway_map(map) do
    %{map |
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
    query_account_balance(address, start, current_time())
  end

  defp get_account_balances_weekly(address) do
    start = Timex.now() |> Timex.shift(days: -7) |> Timex.to_unix()
    query_account_balance(address, start, current_time())
  end

  defp get_account_balances_monthly(address) do
    start = Timex.now() |> Timex.shift(days: -30) |> Timex.to_unix()
    query_account_balance(address, start, current_time())
  end

  defp query_account_balance(address, start, finish) do
    query = from(
      a in AccountBalance,
      where: a.account_address == ^address,
      where: a.block_time >= ^start,
      where: a.block_time <= ^finish,
      select: %{
        time: a.block_time,
        balance: a.balance,
        delta: a.delta
      }
    )

    query |> Repo.all
  end

  defp current_time() do
    Timex.now() |> Timex.to_unix()
  end

  defp sample_daily_account_balance(address) do
    range = 1..24

    range
    |> balance_filter(address, &get_account_balances_daily/1, 1)
    |> populated_time_data()
    |> parse_balance_history(range, address)
  end

  defp sample_weekly_account_balance(address) do
    range = 1..22

    range
    |> balance_filter(address, &get_account_balances_weekly/1, 8)
    |> populated_time_data()
    |> parse_balance_history(range, address)
  end

  defp sample_monthly_account_balance(address) do
    range = 1..31

    range
    |> balance_filter(address, &get_account_balances_monthly/1, 24)
    |> populated_time_data()
    |> parse_balance_history(range, address)
  end

  defp balance_filter(range, address, fun, shift) do
    address
    |> interval_filter(range, fun, shift)
    |> Enum.reduce([], fn list, acc->
      case list do
        list when list != [] ->
          x = list |> Enum.max_by(fn item -> item.time end)
          y = list |> Enum.map(fn item -> item.delta end) |> Enum.sum()
          [%{x | delta: y} | acc]
        _ ->
          [nil | acc]
      end
    end)
    |> Enum.reverse()
  end

  defp interval_filter(address, range, fun, shift) do
    hr_shift = 3600*shift
    offset= rem(current_time(), hr_shift)
    now = div(current_time() - offset, hr_shift)
    then = div(current_time() - (offset + (hr_shift * length(Enum.to_list(range)))), hr_shift)

    map = Range.new(then, now)
          |> Enum.map(fn key -> {key, []} end)
          |> Map.new()

    filtered_map =
      address
      |> fun.()
      |> Enum.group_by(fn x -> div((x.time - offset), hr_shift) end)

    map
    |> Map.merge(filtered_map)
    |> Map.values()
  end

  defp populated_time_data(filtered_time_data) do
    filtered_time_data
    |> Enum.reduce({0, nil, []},
      fn
        (nil, {p, nil, acc}) ->
          {p+1, nil, acc}
        (nil, {_, current_balance, acc}) ->
          {0, current_balance, acc ++ [current_balance]}
        (%{balance: balance}, {0, _, acc0}) ->
          {0, balance, acc0 ++ [balance]}
        (%{balance: balance, delta: delta}, {p, _, acc0}) ->
          acc1 =
            1..p
            |> Enum.to_list()
            |> Enum.reduce([], fn (_, a) -> [balance-delta | a] end)
          {0, balance, acc0 ++ acc1 ++ [balance]}
      end)
  end

  defp parse_balance_history(data, range, address) do
    case data do
      {0, _start, balances} -> balances
      _ -> default_balance_history(range, address)
    end
  end

  defp default_balance_history(range, address) do
    range
    |> Enum.map(fn _i ->
      case get_latest_account_balance!(address) do
        nil -> 0
        account_entry -> account_entry.balance
      end
    end)
  end
end
