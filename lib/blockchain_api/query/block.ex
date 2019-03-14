defmodule BlockchainAPI.Query.Block do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.Block}

  def list(params) do
    Block
    |> order_by([b], desc: b.height)
    |> Repo.paginate(params)
  end

  def get!(height) do
    Block
    |> where([b], b.height == ^height)
    |> Repo.one!
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
