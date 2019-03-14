defmodule BlockchainAPI.Query.Hotspot do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.Hotspot}

  def list(params) do
    Hotspot |> Repo.paginate(params)
  end

  def get!(address) do
    Hotspot
    |> where([h], h.address == ^address)
    |> Repo.one!
  end

  def create(attrs \\ %{}) do
    %Hotspot{}
    |> Hotspot.changeset(attrs)
    |> Repo.insert()
  end

  def update!(hotspot, attrs \\ %{}) do
    hotspot
    |> Hotspot.changeset(attrs)
    |> Repo.update!()
  end
end
