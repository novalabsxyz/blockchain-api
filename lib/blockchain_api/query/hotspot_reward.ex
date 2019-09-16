defmodule BlockchainAPI.Query.HotspotReward do
  @moduledoc false
  import Ecto.Query, warn: false

  @default_limit 100
  @max_limit 500

  alias BlockchainAPI.{Repo, Schema.RewardTxn}

  def list(address, params) do
    address
    |> list_query()
    |> maybe_filter(params)
    |> Repo.all()
  end

  defp list_query(address) do
    from(
      r in RewardTxn,
      where: r.gateway == ^address,
      order_by: [desc: r.id]
    )
  end

  defp maybe_filter(query, %{"before" => before, "limit" => limit0} = _params) do
    limit = min(@max_limit, String.to_integer(limit0))

    query
    |> where([r], r.id < ^before)
    |> limit(^limit)
  end

  defp maybe_filter(query, %{"before" => before} = _params) do
    query
    |> where([r], r.id < ^before)
    |> limit(@default_limit)
  end

  defp maybe_filter(query, %{"limit" => limit0} = _params) do
    limit = min(@max_limit, String.to_integer(limit0))

    query
    |> limit(^limit)
  end

  defp maybe_filter(query, %{}) do
    query
    |> limit(@default_limit)
  end
end
