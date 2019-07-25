defmodule BlockchainAPI.Query.AccountTransaction do
  @moduledoc false
  import Ecto.Query, warn: false
  @default_limit 100

  alias BlockchainAPI.{
    Query,
    Repo,
    Schema.AccountTransaction,
    Schema.CoinbaseTransaction,
    Schema.DataCreditTransaction,
    Schema.GatewayTransaction,
    Schema.Hotspot,
    Schema.HotspotActivity,
    Schema.LocationTransaction,
    Schema.PaymentTransaction,
    Schema.RewardTxn,
    Schema.SecurityTransaction,
    Util
  }

  def create(attrs \\ %{}) do
    %AccountTransaction{}
    |> AccountTransaction.changeset(attrs)
    |> Repo.insert()
  end

  def list(address, %{"before" => before, "limit" => limit}=_params) do

    # NOTE: no pagination for pending recvs
    pp = Query.PendingPayment.get_pending_by_address(address)
    pg = Query.PendingGateway.get_by_owner(address)
    pl = Query.PendingLocation.get_by_owner(address)
    rest =  address
            |> list_query()
            |> filter_before(before, limit)
            |> Repo.all()
            |> format()

    pp ++ pg ++ pl ++ rest
  end
  def list(address, %{"before" => before}=_params) do
    pp = Query.PendingPayment.get_pending_by_address(address)
    pg = Query.PendingGateway.get_by_owner(address)
    pl = Query.PendingLocation.get_by_owner(address)
    rest = address
           |> list_query()
           |> filter_before(before, @default_limit)
           |> Repo.all()
           |> format()

    pp ++ pg ++ pl ++ rest
  end
  def list(address, %{"limit" => limit}=_params) do
    pp = Query.PendingPayment.get_pending_by_address(address)
    pg = Query.PendingGateway.get_by_owner(address)
    pl = Query.PendingLocation.get_by_owner(address)
    rest = address
           |> list_query()
           |> limit(^limit)
           |> Repo.all()
           |> format()

    pp ++ pg ++ pl ++ rest
  end
  def list(address, %{}) do
    pp = Query.PendingPayment.get_pending_by_address(address)
    pg = Query.PendingGateway.get_by_owner(address)
    pl = Query.PendingLocation.get_by_owner(address)
    rest = address
           |> list_query()
           |> Repo.all()
           |> format()

    pp ++ pg ++ pl ++ rest
  end

  def get_pending_txn!(txn_hash) do
    AccountTransaction
    |> where([at], at.txn_hash == ^txn_hash)
    |> where([at], at.txn_status == "pending")
    |> Repo.one!
  end

  def update_pending!(pending, attrs \\ %{}) do
    pending
    |> AccountTransaction.changeset(attrs)
    |> Repo.update!()
  end

  def delete_pending!(pending, attrs \\ %{}) do
    pending
    |> AccountTransaction.changeset(attrs)
    |> Repo.delete!()
  end

  def get_gateways(address, _params \\ %{}) do
    current_height = Query.Block.get_latest_height()

    status_query = from(
      ha in HotspotActivity,
      group_by: ha.gateway,
      select: %{
        gateway: ha.gateway,
        challenge_height: max(ha.poc_req_txn_block_height)
      }
    )

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
      left_join: s in subquery(status_query),
      on: s.gateway == gt.gateway,
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
        score: hotspot.score,
        status: fragment("CASE WHEN ? - ? < 35 THEN 'online' ELSE 'offline' END", ^current_height, s.challenge_height)
      })

    query
    |> Repo.all()
    |> clean_account_gateways()
  end

  #==================================================================
  # Helper functions
  #==================================================================
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
      owner: Util.bin_to_string(map.owner),
      score: Util.rounder(map.score, 4)
    }
  end

  defp list_query(address) do
    pending = list_pending(address)
    cleared = list_cleared(address)

    query = Ecto.Query.union(pending, ^cleared)

    from(
      q in subquery(query),
      order_by: [desc: q.id]
    )
  end

  defp list_pending(address) do
    thirty_mins_ago = Timex.to_naive_datetime(Timex.shift(Timex.now(), minutes: -30))

    from(
      at in AccountTransaction,
      where: at.account_address == ^address,
      where: at.txn_status == "pending",
      where: at.inserted_at >= ^thirty_mins_ago
    )
  end

  defp list_cleared(address) do
    from(
      at in AccountTransaction,
      where: at.account_address == ^address,
      where: at.txn_status == "cleared"
    )
  end

  defp filter_before(query, before, limit) do
    query
    |> where([at], at.id < ^before)
    |> limit(^limit)
  end

  defp format(entries) do
    entries
    |> Enum.reduce([],
      fn(entry, acc) ->
        case entry.txn_status do
          "cleared" ->
            case entry.txn_type do
              "payment" ->
                res = entry.txn_hash
                      |> Query.Transaction.get_payment!()
                      |> PaymentTransaction.encode_model()
                [Map.merge(res, %{id: entry.id}) | acc]
              "coinbase" ->
                res = entry.txn_hash
                      |> Query.Transaction.get_coinbase!()
                      |> CoinbaseTransaction.encode_model()
                [Map.merge(res, %{id: entry.id}) | acc]
              "security" ->
                res = entry.txn_hash
                      |> Query.Transaction.get_security!()
                      |> SecurityTransaction.encode_model()
                [Map.merge(res, %{id: entry.id}) | acc]
              "data_credit" ->
                res = entry.txn_hash
                      |> Query.Transaction.get_data_credit!()
                      |> DataCreditTransaction..encode_model()
                [Map.merge(res, %{id: entry.id}) | acc]
              "gateway" ->
                res = entry.txn_hash
                      |> Query.Transaction.get_gateway!()
                      |> GatewayTransaction.encode_model()
                [Map.merge(res, %{id: entry.id}) | acc]
              "location" ->
                res = entry.txn_hash
                      |> Query.Transaction.get_location!()
                      |> LocationTransaction.encode_model()
                [Map.merge(res, %{id: entry.id}) | acc]
              "consensus_reward" -> merge_reward_entry(entry, acc)
              "securities_reward" -> merge_reward_entry(entry, acc)
              "poc_challengees_reward" -> merge_reward_entry(entry, acc)
              "poc_challengers_reward" -> merge_reward_entry(entry, acc)
              "poc_witnesses_reward" -> merge_reward_entry(entry, acc)
              _ -> acc
            end
          "pending" ->
            case entry.txn_type do
              "payment" ->
                try do
                  res = Query.PendingPayment.get!(entry.txn_hash)
                  [Map.merge(res, %{id: entry.id}) | acc]
                rescue
                  _error in Ecto.NoResultsError ->
                    acc
                end
              "coinbase" ->
                try do
                  res = Query.PendingCoinbase.get!(entry.txn_hash)
                  [Map.merge(res, %{id: entry.id}) | acc]
                rescue
                  _error in Ecto.NoResultsError ->
                    acc
                end
              "gateway" ->
                try do
                  res = Query.PendingGateway.get!(entry.txn_hash)
                  [Map.merge(res, %{id: entry.id}) | acc]
                rescue
                  _error in Ecto.NoResultsError ->
                    acc
                end
              "location" ->
                try do
                  res = Query.PendingLocation.get!(entry.txn_hash)
                  [Map.merge(res, %{id: entry.id}) | acc]
                rescue
                  _error in Ecto.NoResultsError ->
                    acc
                end
            end
        end
      end)
      |> Enum.reverse()
  end

  defp merge_reward_entry(entry, acc) do
    reward = Query.RewardTxn.get!(entry.txn_hash, entry.account_address, entry.txn_type)
    res = RewardTxn.encode_model(reward)
          |> Map.merge(%{height: reward.block_height, time: reward.block_time})

    [Map.merge(res, %{id: entry.id}) | acc]
  end

end
