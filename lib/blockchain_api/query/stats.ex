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

    query_blocks_by_time(start, Util.current_time())
    |> avg_block_interval()
  end

  defp query_blocks_by_time(start, finish) do
    query =
      from(
        b in Block,
        where: b.time >= ^start,
        where: b.time <= ^finish,
        order_by: [desc: b.time],
        select: %{
          time: b.time
        }
      )

    query |> Repo.all()
  end

  defp avg_block_interval([]) do
    0.0
  end

  defp avg_block_interval(blocks) do
    # assumes ordered desc
    for {%{time: time_a}, i} <- Enum.with_index(blocks) do
      case Enum.at(blocks, i + 1) do
        %{time: time_b} -> time_a - time_b
        nil -> nil
      end
    end
    |> Enum.reject(&is_nil/1)
    |> average()
  end

  defp average(list) do
    Enum.sum(list) / length(list)
  end
end
