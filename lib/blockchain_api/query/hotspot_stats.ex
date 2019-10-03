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

  def challenges_completed do
    %{
      "24h" => challenges_completed(Util.shifted_unix_time(hours: -24)),
      "7d" => challenges_completed(Util.shifted_unix_time(days: -7)),
      "30d" => challenges_completed(Util.shifted_unix_time(days: -30)),
      "all_time" => challenges_completed(),
    }
  end

  def consensus_groups do
    %{
      "24h" => consensus_groups(Util.shifted_unix_time(hours: -24)),
      "7d" => consensus_groups(Util.shifted_unix_time(days: -7)),
      "30d" => consensus_groups(Util.shifted_unix_time(days: -30)),
      "all_time" => consensus_groups(),
    }
  end

  def hlm_earned do
    %{
      "24h" => hlm_earned(Util.shifted_unix_time(hours: -24)),
      "7d" => hlm_earned(Util.shifted_unix_time(days: -7)),
      "30d" => hlm_earned(Util.shifted_unix_time(days: -30)),
      "all_time" => hlm_earned(),
    }
  end

  def earning_percentile do
    %{
      "24h" => earning_percentile(Util.shifted_unix_time(hours: -24)),
      "7d" => earning_percentile(Util.shifted_unix_time(days: -7)),
      "30d" => earning_percentile(Util.shifted_unix_time(days: -30)),
      "all_time" => earning_percentile(),
    }
  end

  def challenges_witnessed do
    %{
      "24h" => challenges_witnessed(Util.shifted_unix_time(hours: -24)),
      "7d" => challenges_witnessed(Util.shifted_unix_time(days: -7)),
      "30d" => challenges_witnessed(Util.shifted_unix_time(days: -30)),
      "all_time" => challenges_witnessed(),
    }
  end

  def witnessed_percentile do
    %{
      "24h" => witnessed_percentile(Util.shifted_unix_time(hours: -24)),
      "7d" => witnessed_percentile(Util.shifted_unix_time(days: -7)),
      "30d" => witnessed_percentile(Util.shifted_unix_time(days: -30)),
      "all_time" => witnessed_percentile(),
    }
  end

  defp challenges_completed(start_time \\ 0) do
    from(
      pr in POCReceipt,
      where: pr.timestamp >= ^start_time,
      group_by: pr.gateway,
      select: {pr.gateway, count(pr.id)}
    )
    |> Repo.stream()
  end

  defp consensus_groups(start_time \\ 0) do
    from(
      cm in ConsensusMember,
      inner_join: et in ElectionTransaction,
      on: cm.election_transactions_id == et.id,
      inner_join: t in Transaction,
      on: et.hash == t.hash,
      inner_join: b in Block,
      on: t.block_height == b.height,
      where: b.time >= ^start_time,
      group_by: cm.address,
      select: {cm.address, count(cm.id)}
    )
    |> Repo.stream()
  end

  defp hlm_earned(start_time \\ 0) do
    from(
      rt in RewardTxn,
      inner_join: t in Transaction,
      on: rt.rewards_hash == t.hash,
      inner_join: b in Block,
      on: t.block_height == b.height,
      where: b.time >= ^start_time,
      group_by: rt.gateway,
      select: {rt.gateway, sum(rt.amount)}
    )
    |> Repo.stream()
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
      |> Repo.stream()

    get_percentile(ranking, address)
  end

  defp challenges_witnessed(start_time \\ 0) do
    from(
      pw in POCWitness,
      where: pw.timestamp >= ^start_time,
      group_by: pw.gateway,
      select: {pw.gateway, count(pw.id)}
    )
    |> Repo.stream()
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
      |> Repo.stream()

    get_percentile(ranking, address)
  end

  def furthest_witness do
    from(
      pw in POCWitness,
      group_by: pw.gateway,
      select: {pw.gateway, max(pw.distance)}
    )
    |> Repo.stream()
  end

  def furthest_witness_percentile(address) do
    ranking =
      from(
        pw in POCWitness,
        group_by: pw.gateway,
        order_by: [desc: max(pw.distance)],
        select: pw.gateway
      )
      |> Repo.stream()

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
