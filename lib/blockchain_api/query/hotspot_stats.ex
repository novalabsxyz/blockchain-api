defmodule BlockchainAPI.Query.HotspotStats do
  import Ecto.Query, warn: false

  alias BlockchainAPI.{
    Repo,
    Schema.Block,
    Schema.ConsensusMember,
    Schema.ElectionTransaction,
    Schema.Hotspot,
    Schema.POCReceipt,
    Schema.POCWitness,
    Schema.RewardTxn,
    Schema.Transaction,
    Util
  }

  def challenges_completed_map(address) do
    %{
      "24h" => challenges_completed(address, Util.shifted_unix_time(hours: -24)),
      "7d" => challenges_completed(address, Util.shifted_unix_time(days: -7)),
      "30d" => challenges_completed(address, Util.shifted_unix_time(days: -30)),
      "all_time" => challenges_completed(address),
    }
  end

  def consensus_groups_map(address) do
    %{
      "24h" => consensus_groups(address, Util.shifted_unix_time(hours: -24)),
      "7d" => consensus_groups(address, Util.shifted_unix_time(days: -7)),
      "30d" => consensus_groups(address, Util.shifted_unix_time(days: -30)),
      "all_time" => consensus_groups(address),
    }
  end

  def hlm_earned_map(address) do
    %{
      "24h" => hlm_earned(address, Util.shifted_unix_time(hours: -24)),
      "7d" => hlm_earned(address, Util.shifted_unix_time(days: -7)),
      "30d" => hlm_earned(address, Util.shifted_unix_time(days: -30)),
      "all_time" => hlm_earned(address),
    }
  end

  def earning_percentile_map(address) do
    %{
      "24h" => earning_percentile(address, Util.shifted_unix_time(hours: -24)),
      "7d" => earning_percentile(address, Util.shifted_unix_time(days: -7)),
      "30d" => earning_percentile(address, Util.shifted_unix_time(days: -30)),
      "all_time" => earning_percentile(address),
    }
  end

  def challenges_witnessed_map(address) do
    %{
      "24h" => challenges_witnessed(address, Util.shifted_unix_time(hours: -24)),
      "7d" => challenges_witnessed(address, Util.shifted_unix_time(days: -7)),
      "30d" => challenges_witnessed(address, Util.shifted_unix_time(days: -30)),
      "all_time" => challenges_witnessed(address),
    }
  end

  def witnessed_percentile_map(address) do
    %{
      "24h" => witnessed_percentile(address, Util.shifted_unix_time(hours: -24)),
      "7d" => witnessed_percentile(address, Util.shifted_unix_time(days: -7)),
      "30d" => witnessed_percentile(address, Util.shifted_unix_time(days: -30)),
      "all_time" => witnessed_percentile(address),
    }
  end

  defp challenges_completed(address, start_time \\ 0) do
    from(
      pr in POCReceipt,
      where: pr.gateway == ^address,
      where: pr.timestamp >= ^start_time,
      select: count(pr.id)
    )
    |> Repo.one()
  end

  defp consensus_groups(address, start_time \\ 0) do
    from(
      cm in ConsensusMember,
      where: cm.address == ^address,
      inner_join: et in ElectionTransaction,
      on: cm.election_transactions_id == et.id,
      inner_join: t in Transaction,
      on: et.hash == t.hash,
      inner_join: b in Block,
      on: t.block_height == b.height,
      where: b.time >= ^start_time,
      select: count(cm.id)
    )
    |> Repo.one()
  end

  defp hlm_earned(address, start_time \\ 0) do
    from(
      rt in RewardTxn,
      where: rt.gateway == ^address,
      inner_join: t in Transaction,
      on: rt.rewards_hash == t.hash,
      inner_join: b in Block,
      on: t.block_height == b.height,
      where: b.time >= ^start_time,
      select: sum(rt.amount)
    )
    |> Repo.one()
    |> Kernel.||(0)
  end

  defp earning_percentile(address, start_time \\ 0) do
    ranking =
      from(
        rt in RewardTxn,
        inner_join: t in Transaction,
        on: rt.rewards_hash == t.hash,
        inner_join: b in Block,
        on: t.block_height == b.height,
        where: b.time >= ^start_time,
        group_by: rt.gateway,
        order_by: [desc: sum(rt.amount)],
        select: rt.gateway
      )
      |> Repo.all()

    get_percentile(ranking, address)
  end

  defp challenges_witnessed(address, start_time \\ 0) do
    from(
      pw in POCWitness,
      where: pw.gateway == ^address,
      where: pw.timestamp >= ^start_time,
      select: count(pw.id)
    )
    |> Repo.one()
  end

  defp witnessed_percentile(address, start_time \\ 0) do
    ranking =
      from(
        pw in POCWitness,
        where: pw.timestamp >= ^start_time,
        group_by: pw.gateway,
        order_by: [desc: count(pw.id)],
        select: pw.gateway
      )
      |> Repo.all()

    get_percentile(ranking, address)
  end

  def furthest_witness(address) do
    from(
      pw in POCWitness,
      where: pw.gateway == ^address,
      select: max(pw.distance)
    )
    |> Repo.one()
  end

  def furthest_witness_percentile(address) do
    ranking =
      from(
        pw in POCWitness,
        group_by: pw.gateway,
        order_by: [desc: max(pw.distance)],
        select: pw.gateway
      )
      |> Repo.all()

    get_percentile(ranking, address)
  end

  defp get_percentile([], _), do: 0

  defp get_percentile(ranking, address) do
    n = num_hotspots()
    with true <- n > 1,
         index when is_integer(index) <- Enum.find_index(ranking, & &1 == address) do
      (n - index - 1) / (n - 1)
      |> Kernel.*(100)
      |> Kernel.round()
    else
      _ ->
        0
    end
  end

  defp num_hotspots do
    from(
      h in Hotspot,
      select: count(h.id)
    )
    |> Repo.one()
  end
end
