defmodule BlockchainAPI.Query.LocationTransaction do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, RORepo, Schema.LocationTransaction}

  def list(_params) do
    LocationTransaction
    |> order_by([lt], desc: [lt.id])
    |> RORepo.all()
  end

  def get!(hash) do
    LocationTransaction
    |> where([lt], lt.hash == ^hash)
    |> RORepo.one!()
  end

  def create(attrs \\ %{}) do
    %LocationTransaction{}
    |> LocationTransaction.changeset(attrs)
    |> Repo.insert()
  end
end
