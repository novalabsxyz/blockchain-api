defmodule BlockchainAPI.Query.PendingOUI do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, RORepo, Schema.PendingOUI}

  def create(attrs \\ %{}) do
    %PendingOUI{}
    |> PendingOUI.changeset(attrs)
    |> Repo.insert()
  end

  def get!(hash) do
    PendingOUI
    |> where([poui], poui.hash == ^hash)
    |> RORepo.one!()
  end

  def get_by_id!(id) do
    PendingOUI
    |> where([poui], poui.id == ^id)
    |> RORepo.one!()
  end

  def update!(poui, attrs \\ %{}) do
    poui
    |> PendingOUI.changeset(attrs)
    |> Repo.update!()
  end
end
