defmodule BlockchainAPI.Query.ElectionTransaction do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{
    Repo,
    Schema.Block,
    Schema.ConsensusMember,
    Schema.ElectionTransaction,
    Schema.Hotspot,
    Schema.Transaction,
    Util
  }

  @default_limit 20

  def list(%{"before" => before, "limit" => limit}) do
    list_query()
    |> filter_before(before, limit)
    |> Repo.all()
    |> encode()
  end

  def list(%{"before" => before}) do
    list_query()
    |> filter_before(before, @default_limit)
    |> Repo.all()
    |> encode()
  end

  def list(%{"limit" => limit}) do
    list_query()
    |> limit(^limit)
    |> Repo.all()
    |> encode()
  end

  def list(_) do
    list_query()
    |> Repo.all()
    |> encode()
  end

  def get!(hash) do
    from(
      e in ElectionTransaction,
      preload: [:consensus_members],
      where: e.hash == ^hash
    )
    |> Repo.one!()
    |> encode_entry()
  end

  def create(attrs \\ %{}) do
    %ElectionTransaction{}
    |> ElectionTransaction.changeset(attrs)
    |> Repo.insert()
  end

  def get_consensus_members(election) do
    election
    |> Repo.preload(:consensus_members)
    |> Map.get(:consensus_members)
    |> Enum.map(&encode_member/1)
  end

  defp list_query do
    members_subquery = members_subquery()
    from(
      et in ElectionTransaction,
      join: t in Transaction,
      on: et.hash == t.hash,
      where: t.type == "election",
      left_join: b in Block,
      on: b.height == t.block_height,
      preload: [consensus_members: ^members_subquery],
      order_by: [desc: et.id],
      select: %{election_transaction: et, block: b}
    )
  end

  defp members_subquery do
    from(
      cm in ConsensusMember,
      left_join: h in Hotspot,
      on: cm.address == h.address,
      select: %{address: cm.address, score: h.score}
    )
  end

  defp blocks_subquery do
    from(
      b in Block,
      left_join: t in Transaction,
      on: t.block_height == b.height,
      group_by: b.id,
      order_by: [desc: b.height],
      select: %{height: b.height, hash: b.hash, round: b.round, time: b.time, txns: count(t.id)}
    )
  end

  defp filter_before(query, before, limit) do
    query
    |> where([et], et.id < ^before)
    |> limit(^limit)
  end

  defp encode([]), do: []
  defp encode(entries), do: Enum.map(entries, &encode_entry/1)

  defp encode_entry(%{election_transaction: etxn, block: block}) do
    members = Enum.map(etxn.consensus_members, &encode_member/1)
    block = Block.encode_model(block)


    %{
      id: etxn.id,
      hash: Util.bin_to_string(etxn.hash),
      start_time: block.time,
      members: members,
      block: block
    }
  end

  defp encode_member(%{address: address, score: score}) do
    %{address: Util.bin_to_string(address), score: score}
  end

  defp encode_member(%{address: address}) do
    Util.bin_to_string(address)
  end
end
