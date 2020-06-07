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
    Schema.LocationTransaction,
    Schema.PaymentTransaction,
    Schema.RewardTxn,
    Schema.SecurityTransaction,
    Schema.PaymentV2Txn,
    Util
  }

  # ==================================================================
  # Public functions
  # ==================================================================
  def create(attrs \\ %{}) do
    %AccountTransaction{}
    |> AccountTransaction.changeset(attrs)
    |> Repo.insert()
  end

  def list(address, %{"before" => _before, "limit" => _limit} = params) do
    address
    |> list_query()
    |> maybe_filter(params)
    |> Repo.replica.all()
    |> format()
  end

  def list(address, %{"before" => _before} = params) do
    address
    |> list_query()
    |> maybe_filter(params)
    |> Repo.replica.all()
    |> format()
  end

  def list(address, %{"limit" => limit} = _params) do
    pp = Query.PendingPayment.get_pending_by_address(address)
    pg = Query.PendingGateway.get_by_owner(address)
    pl = Query.PendingLocation.get_by_owner(address)

    rest =
      address
      |> list_query()
      |> limit(^limit)
      |> Repo.replica.all()
      |> format()

    pp ++ pg ++ pl ++ rest
  end

  def list(address, %{}) do
    pp = Query.PendingPayment.get_pending_by_address(address)
    pg = Query.PendingGateway.get_by_owner(address)
    pl = Query.PendingLocation.get_by_owner(address)

    rest =
      address
      |> list_query()
      |> Repo.replica.all()
      |> format()

    pp ++ pg ++ pl ++ rest
  end

  def get_pending_txn!(txn_hash) do
    AccountTransaction
    |> where([at], at.txn_hash == ^txn_hash)
    |> where([at], at.txn_status == "pending")
    |> Repo.replica.one!()
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

  def get_gateways(address, _ \\ %{}) do
    current_height = Query.Block.get_latest_height()
    sql = get_gateways_sql()

    res = Ecto.Adapters.SQL.query!(Repo.replica, sql, [current_height, address])

    res.rows
    |> BlockchainAPI.Util.pmap(
      fn([
        owner,
        account_address,
        gateway_hash,
        gateway,
        payer,
        gateway_fee,
        name,
        added_height,
        location,
        score,
        long_city,
        long_street,
        long_state,
        long_country,
        short_city,
        short_street,
        short_state,
        short_country,
        location_nonce,
        location_fee,
        location_hash,
        location_height,
        challenge_height,
        status
      ]) ->
          {lat, lng} = Util.h3_to_lat_lng(location)
          status = Query.HotspotStatus.consolidate_status(status, gateway)
          sync_percent = Query.HotspotStatus.sync_percent(gateway, current_height)
          %{owner: Util.bin_to_string(owner),
            account_address: Util.bin_to_string(account_address),
            gateway_hash: Util.bin_to_string(gateway_hash),
            gateway: Util.bin_to_string(gateway),
            payer: Util.bin_to_string(payer),
            gateway_fee: gateway_fee,
            name: name,
            added_height: added_height,
            location: location,
            lat: lat,
            lng: lng,
            score: Util.rounder(score, 4),
            long_city: long_city,
            long_street: long_street,
            long_state: long_state,
            long_country: long_country,
            short_city: short_city,
            short_street: short_street,
            short_state: short_state,
            short_country: short_country,
            location_nonce: location_nonce,
            location_fee: location_fee,
            location_hash: Util.bin_to_string(location_hash),
            location_height: location_height,
            challenge_height: challenge_height,
            status: status,
            sync_percent: sync_percent
          }
      end)
  end

  # ==================================================================
  # Helper functions
  # ==================================================================

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

  defp format(entries) do
    entries
    |> Enum.reduce(
      [],
      fn entry, acc ->
        case entry.txn_status do
          "cleared" ->
            case entry.txn_type do
              "payment" ->
                res =
                  entry.txn_hash
                  |> Query.Transaction.get_payment!()
                  |> PaymentTransaction.encode_model()

                [Map.merge(res, %{id: entry.id}) | acc]

              "coinbase" ->
                res =
                  entry.txn_hash
                  |> Query.Transaction.get_coinbase!()
                  |> CoinbaseTransaction.encode_model()

                [Map.merge(res, %{id: entry.id}) | acc]

              "security" ->
                res =
                  entry.txn_hash
                  |> Query.Transaction.get_security!()
                  |> SecurityTransaction.encode_model()

                [Map.merge(res, %{id: entry.id}) | acc]

              "data_credit" ->
                res =
                  entry.txn_hash
                  |> Query.Transaction.get_data_credit!()
                  |> DataCreditTransaction.encode_model()

                [Map.merge(res, %{id: entry.id}) | acc]

              "gateway" ->
                res =
                  entry.txn_hash
                  |> Query.Transaction.get_gateway!()
                  |> GatewayTransaction.encode_model()

                [Map.merge(res, %{id: entry.id}) | acc]

              "location" ->
                res =
                  entry.txn_hash
                  |> Query.Transaction.get_location!()
                  |> LocationTransaction.encode_model()

                [Map.merge(res, %{id: entry.id}) | acc]

              "payment_v2" ->
                res =
                  entry.txn_hash
                  |> Query.Transaction.get_payment_v2!()
                  |> PaymentV2Txn.encode_model()

                [Map.merge(res, %{id: entry.id}) | acc]

              "consensus_reward" ->
                merge_reward_entry(entry, acc)

              "securities_reward" ->
                merge_reward_entry(entry, acc)

              "poc_challengees_reward" ->
                merge_reward_entry(entry, acc)

              "poc_challengers_reward" ->
                merge_reward_entry(entry, acc)

              "poc_witnesses_reward" ->
                merge_reward_entry(entry, acc)

              _ ->
                acc
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
      end
    )
    |> Enum.reverse()
  end

  defp merge_reward_entry(entry, acc) do
    reward = Query.RewardTxn.get!(entry.txn_hash, entry.account_address, entry.txn_type)

    res =
      RewardTxn.encode_model(reward)
      |> Map.merge(%{height: reward.block_height, time: reward.block_time})

    [Map.merge(res, %{id: entry.id}) | acc]
  end

  defp maybe_filter(query, %{"before" => before, "limit" => limit} = _params) do
    query
    |> where([at], at.id < ^before)
    |> limit(^limit)
  end

  defp maybe_filter(query, %{"before" => before} = _params) do
    query
    |> where([at], at.id < ^before)
    |> limit(@default_limit)
  end

  defp get_gateways_sql() do
    """
      select
      a.gateway_owner as owner,
      a.gateway_owner as account_address,
      a.gateway_hash,
      a.gateway,
      a.payer,
      a.gateway_fee,
      a.hotspot_name as name,
      a.added_height,
      a.hotspot_location as location,
      a.hotspot_score as score,
      a.long_city,
      a.long_street,
      a.long_state,
      a.long_country,
      a.short_city,
      a.short_street,
      a.short_state,
      a.short_country,
      a.location_nonce,
      a.location_fee,
      a.location_hash,
      a.location_height,
      b.challenge_height,
      case
          when $1 - b."challenge_height" < 130 then 'online'
          else
          case when a."location_height" = NULL then 'offline'
          else
            case
                when $1 - a."location_height" < 130 then 'online'
                else 'offline'
            end
          end
      end as status
      from
      account_gateway_view as a
      left outer join (
      select
          gateway,
          max(poc_req_txn_block_height) as challenge_height
      from
          hotspot_activity
      where
          gateway in (
          select
              gateway
          from
              account_gateway_view
          where
              gateway_owner = $2)
      group by
          hotspot_activity.gateway) as b on
      a.gateway = b.gateway
      where
      a.gateway_owner = $2
      """
  end

end
