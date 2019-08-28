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

  @default_limit 100

  def list(%{"before" => before, "limit" => limit}) do
    list_query()
    |> filter_before(before, limit)
    |> Repo.all()
    |> format_elections()
  end

  def list(%{"before" => before}) do
    list_query()
    |> filter_before(before, @default_limit)
    |> Repo.all()
    |> format_elections()
  end

  def list(%{"limit" => limit}) do
    list_query()
    |> limit(^limit)
    |> Repo.all()
    |> format_elections()
  end

  def list(_) do
    list_query()
    |> Repo.all()
    |> format_elections()
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
      e1 in ElectionTransaction,
      preload: [consensus_members: ^members_subquery],
      join: t1 in Transaction,
      on: e1.hash == t1.hash,
      left_join: e0 in ElectionTransaction,
      on: e0.id == e1.id - 1,
      left_join: t0 in Transaction,
      on: t0.hash == e0.hash,
      join: b in Block,
      on: b.height > t0.block_height and b.height <= t1.block_height,
      order_by: [desc: e1.id],
      select: %{election_transaction: e1, block: b}
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

  defp filter_before(query, before, limit) do
    query
    |> where([et], et.id < ^before)
    |> limit(^limit)
  end

  defp format_elections([]), do: []
  defp format_elections(entries) do
    entries
    |> Enum.group_by(&Map.get(&1, :election_transaction), &Map.get(&1, :block))
    |> Enum.map(&encode_entry/1)
  end

  defp encode_entry({etxn, blocks}) do
    members = Enum.map(etxn.consensus_members, &encode_member/1)
    blocks =
      blocks
      |> Enum.sort(& Map.get(&1, :height) < Map.get(&2, :height))
      |> Enum.map(&Block.encode_model/1)


    %{
      id: etxn.id,
      blocks_count: length(blocks),
      hash: Util.bin_to_string(etxn.hash),
      start_time: List.first(blocks) |> Map.get(:time),
      end_time: List.last(blocks) |> Map.get(:time),
      members: members,
      blocks: blocks
    }
  end

  defp encode_member(%{address: address, score: score}) do
    %{address: Util.bin_to_string(address), score: score}
  end

  defp encode_member(%{address: address}) do
    Util.bin_to_string(address)
  end
end
