defmodule BlockchainAPI.Query.PendingLocation do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.PendingLocation}

  def create(attrs \\ %{}) do
    %PendingLocation{}
    |> PendingLocation.changeset(attrs)
    |> Repo.insert()
  end

  def get!(hash) do
    PendingLocation
    |> where([pl], pl.hash == ^hash)
    |> Repo.one!
  end

  def get_by_id!(id) do
    PendingLocation
    |> where([pl], pl.id == ^id)
    |> Repo.one!()
  end

  def update!(pl, attrs \\ %{}) do
    pl
    |> PendingLocation.changeset(attrs)
    |> Repo.update!()
  end
end
