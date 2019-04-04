defmodule BlockchainAPI.Query.POCReceipt do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.POCReceipt}

  def list(_) do
    POCReceipt
    |> Repo.all()
  end

  def create(attrs \\ %{}) do
    %POCReceipt{}
    |> POCReceipt.changeset(attrs)
    |> Repo.insert()
  end
end
