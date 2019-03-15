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

    query |> Repo.paginate(params) |> encode()
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
end
