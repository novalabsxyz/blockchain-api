defmodule BlockchainAPI.Query.PendingLocation do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.PendingLocation}

  def create_pending_location(attrs \\ %{}) do
    %PendingLocation{}
    |> PendingLocation.changeset(attrs)
    |> Repo.insert()
  end

  def get_pending_location!(hash) do
    PendingLocation
    |> where([pl], pl.hash == ^hash)
    |> Repo.one!
  end

  def update_pending_location!(pl, attrs \\ %{}) do
    pl
    |> PendingLocation.changeset(attrs)
    |> Repo.update!()
  end
end
