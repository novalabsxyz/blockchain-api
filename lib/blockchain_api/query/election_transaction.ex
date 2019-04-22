defmodule BlockchainAPI.Query.ElectionTransaction do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Util, Schema.ElectionTransaction}

  def list(_params) do
    from(
      e in ElectionTransaction,
      preload: [:consensus_members],
      order_by: [desc: e.id]
    )
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

  defp format_elections([]), do: []
  defp format_elections(entries) do
    entries |> Enum.map(&encode_entry/1)
  end

  defp encode_entry(entry) do
    members = entry.consensus_members |> Enum.map(&encode_member/1)
    %{
      members: members,
      proof: Util.bin_to_string(entry.proof),
      hash: Util.bin_to_string(entry.hash),
      election_height: entry.election_height,
      delay: entry.delay
    }
  end

  defp encode_member(member) do
    Util.bin_to_string(member.address)
  end

end
