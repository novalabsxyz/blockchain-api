defmodule BlockchainAPI.Query.HotspotStats do
  import Ecto.Query, warn: false

  alias BlockchainAPI.{
    Cache,
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

  def individual_stats(address) do
    address = Util.string_to_bin(address)

    %{
      challenges_completed: Cache.HotspotStats.challenges_completed(address),
      consensus_groups: Cache.HotspotStats.consensus_groups(address),
      hlm_earned: Cache.HotspotStats.hlm_earned(address),
      earning_percentile: Cache.HotspotStats.earning_percentile(address),
      challenges_witnessed: Cache.HotspotStats.challenges_witnessed(address),
      witnessed_percentile: Cache.HotspotStats.witnessed_percentile(address),
      furthest_witness: Cache.HotspotStats.furthest_witness(address),
      furthest_witness_percentile: Cache.HotspotStats.furthest_witness_percentile(address)
    }
  end

  def challenges_completed_map do
    %{
      "24h" => challenges_completed(Util.shifted_unix_time(hours: -24)),
      "7d" => challenges_completed(Util.shifted_unix_time(days: -7)),
      "30d" => challenges_completed(Util.shifted_unix_time(days: -30)),
      "all_time" => challenges_completed(),
    }
  end

  def consensus_groups_map do
    %{
      "24h" => consensus_groups(Util.shifted_unix_time(hours: -24)),
      "7d" => consensus_groups(Util.shifted_unix_time(days: -7)),
      "30d" => consensus_groups(Util.shifted_unix_time(days: -30)),
      "all_time" => consensus_groups(),
    }
  end

  def hlm_earned_map do
    %{
      "24h" => hlm_earned(Util.shifted_unix_time(hours: -24)),
      "7d" => hlm_earned(Util.shifted_unix_time(days: -7)),
      "30d" => hlm_earned(Util.shifted_unix_time(days: -30)),
      "all_time" => hlm_earned(),
    }
  end

  def earning_percentiles_map do
    %{
      "24h" => earning_percentiles(Util.shifted_unix_time(hours: -24)),
      "7d" => earning_percentiles(Util.shifted_unix_time(days: -7)),
      "30d" => earning_percentiles(Util.shifted_unix_time(days: -30)),
      "all_time" => earning_percentiles(),
    }
  end

  def challenges_witnessed_map do
    %{
      "24h" => challenges_witnessed(Util.shifted_unix_time(hours: -24)),
      "7d" => challenges_witnessed(Util.shifted_unix_time(days: -7)),
      "30d" => challenges_witnessed(Util.shifted_unix_time(days: -30)),
      "all_time" => challenges_witnessed(),
    }
  end

  def witnessed_percentiles_map do
    %{
      "24h" => witnessed_percentiles(Util.shifted_unix_time(hours: -24)),
      "7d" => witnessed_percentiles(Util.shifted_unix_time(days: -7)),
      "30d" => witnessed_percentiles(Util.shifted_unix_time(days: -30)),
      "all_time" => witnessed_percentiles(),
    }
  end

  defp challenges_completed(start_time \\ 0) do
    from(
      pr in POCReceipt,
      where: pr.timestamp >= ^start_time,
      group_by: pr.gateway,
      select: {pr.gateway, count(pr.id)}
    )
    |> Repo.all()
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
    |> Repo.all()
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
    |> Repo.all()
  end

  defp earning_percentiles(start_time \\ 0) do
    rewards_subquery =
      from(
        rt in RewardTxn,
        inner_join: t in Transaction,
        on: rt.rewards_hash == t.hash,
        inner_join: b in Block,
        on: t.block_height == b.height,
        where: b.time >= ^start_time,
        group_by: rt.gateway,
        select: %{gateway: rt.gateway, hlm_earned: sum(rt.amount)}
      )
      |> Repo.all()

    from(
      h in Hotspot,
      left_join: r in ^rewards_subquery,
      on: r.gateway == h.address,
      select: {h.address, (over(rank(), order_by: [asc: r.hlm_earned]) - 1) / (count(h.id) -1)}
    )
    |> Repo.all()
  end

  defp challenges_witnessed(start_time \\ 0) do
    from(
      pw in POCWitness,
      where: pw.timestamp >= ^start_time,
      group_by: pw.gateway,
      select: {pw.gateway, count(pw.id)}
    )
    |> Repo.all()
  end

  defp witnessed_percentiles(start_time \\ 0) do
    witness_subquery =
      from(
        pw in POCWitness,
        where: pw.timestamp >= ^start_time,
        group_by: pw.gateway,
        select: %{gateway: pw.gateway, witnessed: count(pw.id)}
      )

    from(
      h in Hotspot,
      left_join: pw in ^witness_subquery,
      on: pw.gateway == h.address,
      select: {h.address, (over(rank(), order_by: [asc: pw.witnessed]) - 1) / (count(h.id) -1)}
    )
    |> Repo.all()
  end

  def furthest_witnesses do
    from(
      pw in POCWitness,
      group_by: pw.gateway,
      select: {pw.gateway, max(pw.distance)}
    )
    |> Repo.all()
  end

  def furthest_witness_percentiles do
    witness_subquery =
      from(
        pw in POCWitness,
        group_by: pw.gateway,
        select: %{gateway:  pw.gateway, distance: max(pw.distance)}
      )

    from(
      h in Hotspot,
      left_join: pw in ^witness_subquery,
      on: pw.gateway == h.address,
      select: {h.address, (over(rank(), order_by: [asc: pw.distance]) - 1) / (count(h.id) -1)}
    )
    |> Repo.all()
  end
end
