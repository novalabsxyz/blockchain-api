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
    |> Repo.one!()
  end

  def get_all_by_hash(hash) do
    PendingLocation
    |> where([pl], pl.hash == ^hash)
    |> Repo.all()
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

  def list_pending() do
    PendingLocation
    |> where([pl], pl.status == "pending")
    |> Repo.all()
  end

  def get_by_owner(address) do
    from(
      pl in PendingLocation,
      where: pl.owner == ^address,
      where: pl.status == "pending",
      where: pl.status != "error",
      where: pl.status != "cleared",
      select: pl
    )
    |> Repo.all()
    |> format()
  end

  def get(owner, gateway, nonce) do
    from(
      pl in PendingLocation,
      where: pl.owner == ^owner,
      where: pl.gateway == ^gateway,
      where: pl.nonce == ^nonce,
      select: pl
    )
    |> Repo.all()
    |> format()
  end

  # ==================================================================
  # Helper functions
  # ==================================================================
  defp format(entries) do
    entries
    |> Enum.map(&format_one/1)
  end

  defp format_one(nil), do: %{}

  defp format_one(entry) do
    Map.merge(entry, %{type: "location"})
  end
end
