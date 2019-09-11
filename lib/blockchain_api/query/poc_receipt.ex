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

  def list_for(hotspot_address) do
    POCReceipt
    |> where([p], p.gateway == ^hotspot_address)
    |> Repo.all()
  end
end
