defmodule BlockchainAPI.Query.HotspotReward do
  @moduledoc false
  import Ecto.Query, warn: false

  @default_limit 100
  @max_limit 500

  # alias BlockchainAPI.{Repo, Util, Schema.RewardTxn}
  alias BlockchainAPI.{Repo, Schema.RewardTxn}

  def list(address, %{"before" => before, "limit" => limit0}=_params) do
    limit =
      case String.to_integer(limit0) > @max_limit do
        true -> @max_limit
        false -> limit0
      end

    address
    |> list_query()
    |> filter_before(before, limit)
    |> Repo.all()
    # |> encode()
  end
  def list(address, %{"before" => before}=_params) do
    address
    |> list_query()
    |> filter_before(before, @default_limit)
    |> Repo.all()
    # |> encode()
  end
  def list(address, %{"limit" => limit0}=_params) do
    limit =
      case String.to_integer(limit0) > @max_limit do
        true -> @max_limit
        false -> limit0
      end
    address
    |> list_query()
    |> limit(^limit)
    |> Repo.all()
    # |> encode()
  end
  def list(address, %{}) do
    address
    |> list_query()
    |> limit(^@default_limit)
    |> Repo.all()
    # |> encode()
  end

  defp list_query(address) do
    from(
      r in RewardTxn,
      where: r.gateway == ^address,
      order_by: [desc: r.id]
    )
  end

  defp filter_before(query, before, limit) do
    query
    |> where([r], r.id < ^before)
    |> limit(^limit)
  end
end
