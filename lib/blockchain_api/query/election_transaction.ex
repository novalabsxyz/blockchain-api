defmodule BlockchainAPI.Query.ElectionTransaction do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{
    Query,
    Repo,
    Schema.Block,
    Schema.ElectionTransaction,
    Schema.Transaction,
    Util
  }

  @default_limit 20

  def list(params) do
    list_query()
    |> maybe_filter(params)
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

  def get_consensus_group(hash) do
    hash = Util.string_to_bin(hash)

    from(
      et in ElectionTransaction,
      where: et.hash == ^hash,
      join: t in Transaction,
      on: et.hash == t.hash,
      left_join: b in Block,
      on: b.height == t.block_height + 1,
      preload: [:consensus_members],
      select: %{etxn: et, start_block: b}
    )
    |> Repo.one()
    |> with_end_block()
    |> encode_group_entry()
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

  def with_end_block(%{start_block: nil} = group) do
    Map.put(group, :end_block, %{end_time: nil, blocks_count: nil})
  end

  def with_end_block(%{start_block: start_block} = group) do
    {end_time, blocks_count} =
      case start_block |> end_block_query() |> Repo.one() do
        nil ->
          {nil, Query.Block.get_latest_height() - start_block.height}

        {end_time, end_height} ->
          {end_time, end_height - start_block.height}
      end

    Map.put(group, :end_block, %{end_time: end_time, blocks_count: blocks_count})
  end

  def with_end_block(nil), do: nil

  defp list_query do
    from(
      from et in ElectionTransaction,
        join: t in Transaction,
        on: t.hash == et.hash,
        left_join: b in Block,
        on: b.height == t.block_height + 1,
        order_by: [desc: t.id],
        select: %{etxn: et, start_block: b}
    )
  end

  defp end_block_query(start_block) do
    from(
      t in Transaction,
      where: t.type == "election",
      where: t.block_height > ^start_block.height,
      left_join: b in Block,
      where: b.height == t.block_height,
      order_by: [asc: b.id],
      limit: 1,
      select: {b.time, b.height}
    )
  end

  defp maybe_filter(query, %{"before" => before, "limit" => limit}) do
    query
    |> where([et], et.id < ^before)
    |> limit(^limit)
  end

  defp maybe_filter(query, %{"before" => before}) do
    query
    |> where([et], et.id < ^before)
    |> limit(@default_limit)
  end

  defp maybe_filter(query, %{"limit" => limit}) do
    query
    |> limit(^limit)
  end

  defp maybe_filter(query, _) do
    query
    |> limit(@default_limit)
  end

  defp encode([]), do: []
  defp encode(entries), do: Enum.map(entries, &encode_list_entry/1)

  defp encode_list_entry(%{etxn: etxn, start_block: start_block}) do
    start_block =
      case start_block do
        nil -> %{height: nil, time: nil}
        start_block -> start_block
      end

    %{
      id: etxn.id,
      proof: Util.bin_to_string(etxn.proof),
      hash: Util.bin_to_string(etxn.hash),
      election_height: etxn.election_height,
      start_height: start_block.height,
      delay: etxn.delay,
      start_time: start_block.time
    }
  end

  defp encode_group_entry(%{etxn: etxn, start_block: start_block, end_block: end_block}) do
    members = Enum.map(etxn.consensus_members, &encode_member/1)

    start_block =
      case start_block do
        nil -> %{height: nil, time: nil}
        start_block -> start_block
      end

    %{
      members: members,
      proof: Util.bin_to_string(etxn.proof),
      hash: Util.bin_to_string(etxn.hash),
      election_height: etxn.election_height,
      start_time: start_block.time,
      end_time: end_block.end_time,
      blocks_count: end_block.blocks_count,
      start_height: start_block.height,
      delay: etxn.delay
    }
  end

  defp encode_group_entry(nil), do: %{}

  defp encode_entry(etxn) when not is_nil(etxn) do
    members = Enum.map(etxn.consensus_members, &encode_member/1)

    %{
      members: members,
      proof: Util.bin_to_string(etxn.proof),
      hash: Util.bin_to_string(etxn.hash),
      election_height: etxn.election_height,
      delay: etxn.delay
    }
  end

  defp encode_entry(nil), do: %{}

  defp encode_member(%{address: address, score: score}) do
    %{address: Util.bin_to_string(address), score: score}
  end

  defp encode_member(%{address: address}) do
    Util.bin_to_string(address)
  end
end
