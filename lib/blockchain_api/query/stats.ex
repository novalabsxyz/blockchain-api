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
    ElectionTransaction,
    Transaction
  }

  def list() do
    Cache.Util.get(:stats_cache, :stats, &set_list/0, @cache_timeout)
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

  defp normalize_interval(interval) do
    case interval do
      nil -> 0.0
      interval -> interval |> Decimal.to_float()
    end
  end
end
