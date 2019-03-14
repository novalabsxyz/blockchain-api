defmodule BlockchainAPI.Query.Hotspot do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.Hotspot}

  def list_hotspots(params) do
    Hotspot |> Repo.paginate(params)
  end

  def get_hotspot!(address) do
    Hotspot
    |> where([h], h.address == ^address)
    |> Repo.one!
  end

  def create_hotspot(attrs \\ %{}) do
    %Hotspot{}
    |> Hotspot.changeset(attrs)
    |> Repo.insert()
  end

  def update_hotspot!(hotspot, attrs \\ %{}) do
    hotspot
    |> Hotspot.changeset(attrs)
    |> Repo.update!()
  end
end
