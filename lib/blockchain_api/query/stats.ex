defmodule BlockchainAPI.Query.Stats do
  @moduledoc false
  import Ecto.Query, warn: false
  use Timex

  alias BlockchainAPI.{Repo, Util}

  alias BlockchainAPI.Schema.{
    Account,
    Block
  }

  def list() do
    %{
      "token_supply" => %{
        "total" => get_supply()
      },
      "block_time" => %{
        "24h" => get_block_time(hours: -24),
        "7d" => get_block_time(days: -7),
        "30d" => get_block_time(days: -30)
      }
    }
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

  defp query_block_interval(start, finish) do
    interval_query =
      from(
        b_0 in Block,
        where: b_0.time >= ^start,
        where: b_0.time <= ^finish,
        left_join: b_1 in Block,
        on: b_1.height == b_0.height - 1,
        where: not is_nil(b_1.time),
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

    case avg_interval do
      nil -> 0.0
      avg_interval -> avg_interval |> Decimal.to_float()
    end
  end
end
