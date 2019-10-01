defmodule BlockchainAPI.Query.Stats do
  @moduledoc false
  import Ecto.Query, warn: false
  use Timex

  # NOTE: Set stats cache timeout to 30 minutes.
  # This is far higher than what we set for other caches,
  # simply because we expect the stats to change less often
  # and don't want to bog the API with calls to DB.
  @cache_timeout :timer.minutes(30)

  alias BlockchainAPI.{Repo, Util, Cache}

  alias BlockchainAPI.Schema.{
    Account,
    Block,
    ConsensusMember,
    ElectionTransaction,
    POCPathElement,
    POCReceiptsTransaction,
    POCWitness,
    RewardTxn,
    Transaction
  }

  def list() do
    Cache.Util.get(:stats_cache, :stats, &set_list/0, @cache_timeout)
    # {:commit, data} = set_list()
    # data
  end

  defp set_list() do
    %{avg_time_interval: day_election_time, avg_block_interval: day_election_block} =
      get_election_time(hours: -24)

    %{avg_time_interval: week_election_time, avg_block_interval: week_election_block} =
      get_election_time(days: -7)

    %{avg_time_interval: month_election_time, avg_block_interval: month_election_block} =
      get_election_time(days: -30)

    data = %{
      "token_supply" => %{
        "total" => get_supply()
      },
      "block_time" => %{
        "24h" => get_block_time(hours: -24),
        "7d" => get_block_time(days: -7),
        "30d" => get_block_time(days: -30)
      },
      "election_time" => %{
        "24h" => day_election_time,
        "7d" => week_election_time,
        "30d" => month_election_time
      },
      "election_blocks" => %{
        "24h" => day_election_block,
        "7d" => week_election_block,
        "30d" => month_election_block
      },
      "leaders" => %{
        "most_frequent_consensus_members" => %{
          "24h" => get_query_by_shift(&query_frequent_concensus_members/2, hours: -24),
          "7d" => get_query_by_shift(&query_frequent_concensus_members/2, days: -7),
          "30d" => get_query_by_shift(&query_frequent_concensus_members/2, days: -30)
        },
        "top_grossing_hotspots" => %{
          "24h" => get_query_by_shift(&query_top_grossing_hotspots/2, hours: -24),
          "7d" => get_query_by_shift(&query_top_grossing_hotspots/2, days: -7),
          "30d" => get_query_by_shift(&query_top_grossing_hotspots/2, days: -30)
        },
        "farthest_witness" => %{
          "24h" => get_query_by_shift(&query_farthest_witness/2, hours: -24),
          "7d" => get_query_by_shift(&query_farthest_witness/2, days: -7),
          "30d" => get_query_by_shift(&query_farthest_witness/2, days: -30)
        }
      }
    }

    {:commit, data}
  end

  def get_supply() do
    from(
      a in Account,
      select: sum(a.balance)
    )
    |> Repo.one()
    |> Decimal.to_integer()
  end

  def get_block_time(shift) do
    start = Util.shifted_unix_time(shift)

    query_block_interval(start, Util.current_time())
  end

  def get_election_time(shift) do
    start = Util.shifted_unix_time(shift)

    query_election_interval(start, Util.current_time())
  end

  def get_query_by_shift(query, shift) do
    start = Util.shifted_unix_time(shift)

    query.(start, Util.current_time())
  end

  defp query_block_interval(start, finish) do
    interval_query =
      from(
        b_0 in Block,
        where: b_0.time >= ^start,
        where: b_0.time <= ^finish,
        inner_join: b_1 in Block,
        on: b_1.height == b_0.height - 1,
        order_by: [desc: b_0.height],
        select: %{
          interval: b_0.time - b_1.time
        }
      )

    query =
      from(
        sq in subquery(interval_query),
        select: %{
          avg_interval: avg(sq.interval)
        }
      )

    %{avg_interval: avg_interval} = query |> Repo.one()

    avg_interval |> normalize_interval()
  end

  defp query_election_interval(start, finish) do
    election_query =
      from(
        et in ElectionTransaction,
        windows: [w: [order_by: et.id]],
        select: %{
          hash: et.hash,
          previous_hash: lag(et.hash) |> over(:w)
        }
      )

    interval_query =
      from(
        eq in subquery(election_query),
        inner_join: t_0 in Transaction,
        on: eq.previous_hash == t_0.hash,
        inner_join: b_0 in Block,
        on: t_0.block_height == b_0.height,
        inner_join: t_1 in Transaction,
        on: eq.hash == t_1.hash,
        inner_join: b_1 in Block,
        on: t_1.block_height == b_1.height,
        where: b_0.time >= ^start,
        where: b_0.time <= ^finish,
        order_by: [desc: b_0.height],
        select: %{
          time_interval: b_1.time - b_0.time,
          block_interval: b_1.height - b_0.height
        }
      )

    query =
      from(
        iq in subquery(interval_query),
        select: %{
          avg_time_interval: avg(iq.time_interval),
          avg_block_interval: avg(iq.block_interval)
        }
      )

    %{avg_time_interval: avg_time_interval, avg_block_interval: avg_block_interval} =
      query |> Repo.one()

    %{
      avg_block_interval: avg_block_interval |> normalize_interval(),
      avg_time_interval: avg_time_interval |> normalize_interval()
    }
  end

  defp query_frequent_concensus_members(start, finish) do
    count_query =
      from(
        b in Block,
        inner_join: tx in Transaction,
        on: b.height == tx.block_height,
        inner_join: et in ElectionTransaction,
        on: tx.hash == et.hash,
        inner_join: cm in ConsensusMember,
        on: et.id == cm.election_transactions_id,
        where: b.time >= ^start,
        where: b.time <= ^finish,
        where: tx.type == "election",
        group_by: cm.address,
        select: %{
          count: fragment("count(*)"),
          gateway: cm.address
        }
      )

    rank_query =
      from(
        cq in subquery(count_query),
        select: %{
          count: cq.count,
          gateway: cq.gateway,
          rank: rank() |> over(order_by: [desc: cq.count])
        }
      )

    query =
      from(
        rq in subquery(rank_query),
        where: rq.rank == 1,
        select: %{
          count: rq.count,
          gateway: rq.gateway
        }
      )

    query
    |> Repo.all()
    |> Enum.map(fn %{gateway: gateway} = m ->
      m |> Map.put(:gateway, Util.bin_to_string(gateway))
    end)
  end

  defp query_top_grossing_hotspots(start, finish) do
    sum_query =
      from(
        b in Block,
        inner_join: tx in Transaction,
        on: b.height == tx.block_height,
        inner_join: rt in RewardTxn,
        on: tx.hash == rt.rewards_hash,
        where: tx.type == "rewards",
        where: b.time >= ^start,
        where: b.time <= ^finish,
        where: not is_nil(rt.gateway),
        group_by: rt.gateway,
        select: %{
          amount: sum(rt.amount),
          gateway: rt.gateway
        }
      )

    rank_query =
      from(
        sq in subquery(sum_query),
        select: %{
          amount: sq.amount,
          gateway: sq.gateway,
          rank: rank() |> over(order_by: [desc: sq.amount])
        }
      )

    query =
      from(
        rq in subquery(rank_query),
        where: rq.rank == 1,
        select: %{
          amount: rq.amount,
          gateway: rq.gateway
        }
      )

    query
    |> Repo.all()
    |> Enum.map(fn %{gateway: gateway} = m ->
      m |> Map.put(:gateway, Util.bin_to_string(gateway))
    end)
  end

  defp query_farthest_witness(start, finish) do
    distance_query =
      from(
        pw in POCWitness,
        where: pw.timestamp / 1000000000 >= ^start,
        where: pw.timestamp / 1000000000 <= ^finish,
        select: %{
          gateway: pw.gateway,
          distance: pw.distance,
          timestamp: pw.timestamp
        }
      )

    rank_query =
      from(
        dq in subquery(distance_query),
        select: %{
          gateway: dq.gateway,
          distance: dq.distance,
          rank: rank() |> over(order_by: [desc: dq.distance, asc: dq.timestamp])
        }
      )

    query =
      from(
        rq in subquery(rank_query),
        where: rq.rank == 1,
        select: %{
          gateway: rq.gateway,
          distance: rq.distance
        }
      )

    query
    |> Repo.all()
    |> Enum.map(fn %{gateway: gateway} = m ->
      m
      |> Map.put(:gateway, Util.bin_to_string(gateway))
    end)
  end

  defp normalize_interval(interval) do
    case interval do
      nil -> 0.0
      interval -> interval |> Decimal.to_float()
    end
  end

  defp print_sql(queryable) do
    {query, params} = Ecto.Adapters.SQL.to_sql(:all, Repo, queryable)
    IO.puts("#{query}, #{inspect(params)}")
    queryable
  end
end
