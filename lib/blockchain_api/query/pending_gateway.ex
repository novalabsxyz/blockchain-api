defmodule BlockchainAPI.Query.PendingGateway do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.PendingGateway}

  def create(attrs \\ %{}) do
    %PendingGateway{}
    |> PendingGateway.changeset(attrs)
    |> Repo.insert()
  end

  def get!(hash) do
    PendingGateway
    |> where([pg], pg.hash == ^hash)
    |> Repo.one!()
  end

  def get_all_by_hash(hash) do
    PendingGateway
    |> where([pg], pg.hash == ^hash)
    |> Repo.all()
  end

  def get_by_id!(id) do
    PendingGateway
    |> where([pg], pg.id == ^id)
    |> Repo.one!()
  end

  def get(owner, gateway) do
    from(
      pg in PendingGateway,
      where: pg.owner == ^owner,
      where: pg.gateway == ^gateway,
      select: pg
    )
    |> Repo.one()
    |> format_one()
  end

  def update!(pg, attrs \\ %{}) do
    pg
    |> PendingGateway.changeset(attrs)
    |> Repo.update!()
  end

  def list_pending() do
    PendingGateway
    |> where([pg], pg.status == "pending")
    |> Repo.all()
  end

  def get_by_owner(address) do
    from(
      pg in PendingGateway,
      where: pg.owner == ^address,
      where: pg.status == "pending",
      where: pg.status != "error",
      where: pg.status != "cleared",
      select: pg
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
    Map.merge(entry, %{type: "gateway"})
  end
end
