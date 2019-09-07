defmodule BlockchainAPI.Query.ElectionTransaction do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{
    Repo,
    Schema.Block,
    Schema.ElectionTransaction,
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

  def get(hash) do
    hash = Util.string_to_bin(hash)
    from(
      e in ElectionTransaction,
      preload: [:consensus_members],
      where: e.hash == ^hash
    )
    |> Repo.one()
    |> encode_entry()
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
    from(
      from et in ElectionTransaction,
      join: t in Transaction,
      on: t.hash == et.hash,
      left_join: b in Block,
      on: t.block_height == b.height,
      order_by: [desc: t.id],
      select: %{etxn: et, block: b}
    )
  end

  defp filter_before(query, before, limit) do
    query
    |> where([et], et.id < ^before)
    |> limit(^limit)
  end

  defp encode([]), do: []
  defp encode(entries), do: Enum.map(entries, &encode_entry/1)

  defp encode_entry(%{etxn: etxn, block: block}) do
    %{
      id: etxn.id,
      proof: Util.bin_to_string(etxn.proof),
      hash: Util.bin_to_string(etxn.hash),
      election_height: etxn.election_height,
      delay: etxn.delay,
      start_time: block.time
    }
  end

  defp encode_entry(entry) when not is_nil(entry) do
    members = Enum.map(entry.consensus_members, &encode_member/1)

    %{
      members: members,
      proof: Util.bin_to_string(entry.proof),
      hash: Util.bin_to_string(entry.hash),
      election_height: entry.election_height,
      delay: entry.delay
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
