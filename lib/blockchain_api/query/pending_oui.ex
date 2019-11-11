defmodule BlockchainAPI.Query.PendingOUI do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.PendingOUI}

  def create(attrs \\ %{}) do
    %PendingOUI{}
    |> PendingOUI.changeset(attrs)
    |> Repo.insert()
  end

  def get!(hash) do
    PendingOUI
    |> where([poui], poui.hash == ^hash)
    |> Repo.one!()
  end

  def get_by_id!(id) do
    PendingOUI
    |> where([poui], poui.id == ^id)
    |> Repo.one!()
  end

  def update!(poui, attrs \\ %{}) do
    poui
    |> PendingOUI.changeset(attrs)
    |> Repo.update!()
  end

  def get_by_owner(address) do
    from(
      poui in PendingOUI,
      where: poui.owner == ^address
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
    Map.merge(entry, %{type: "oui"})
  end
end
