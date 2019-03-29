defmodule BlockchainAPI.Query.Block do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Util, Schema.Block, Schema.Transaction}

  def list(params) do
    query = from(
      block in Block,
      full_join: txn in Transaction,
      on: block.height == txn.block_height,
      group_by: block.id,
      order_by: [desc: block.height],
      select: %{
        hash: block.hash,
        height: block.height,
        time: block.time,
        round: block.round,
        txns: count(txn.id)
      })

    query
    |> Repo.all()
    |> encode()
  end

  def get!(height) do

    query = from(
      block in Block,
      full_join: txn in Transaction,
      on: block.height == txn.block_height,
      where: block.height == ^height,
      group_by: block.id,
      order_by: [desc: block.height],
      select: %{
        hash: block.hash,
        height: block.height,
        time: block.time,
        round: block.round,
        txns: count(txn.id)
      })

    query |> Repo.one!() |> encode()
  end

  def create(attrs \\ %{}) do
    %Block{}
    |> Block.changeset(attrs)
    |> Repo.insert()
  end

  def get_latest() do
    query = from block in Block, select: max(block.height)
    Repo.all(query)
  end

  #==================================================================
  # Helper functions
  #==================================================================
  defp encode(nil), do: nil
  defp encode(%{hash: hash}=block) do
    %{block | hash: Util.bin_to_string(hash)}
  end
  defp encode(entries) when is_list(entries) do
    entries
    |> Enum.map(fn %{hash: hash}=block ->
      %{block | hash: Util.bin_to_string(hash)}
    end)
  end
end
