defmodule BlockchainAPI.Query.LocationTransaction do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.LocationTransaction}

  def list(_params) do
    LocationTransaction
    |> order_by([lt], desc: [lt.id])
    |> Repo.all()
  end

  def get!(hash) do
    LocationTransaction
    |> where([lt], lt.hash == ^hash)
    |> Repo.one!
  end

  def create(attrs \\ %{}) do
    %LocationTransaction{}
    |> LocationTransaction.changeset(attrs)
    |> Repo.insert()
  end
end
