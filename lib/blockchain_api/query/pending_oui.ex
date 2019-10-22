defmodule BlockchainAPI.Query.PendingOui do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.PendingOui}

  def create(attrs \\ %{}) do
    %PendingOui{}
    |> PendingOui.changeset(attrs)
    |> Repo.insert()
  end

  def get!(hash) do
    PendingOui
    |> where([poui], poui.hash == ^hash)
    |> Repo.one!()
  end

  def get_by_id!(id) do
    PendingOui
    |> where([poui], poui.id == ^id)
    |> Repo.one!()
  end

  def update!(poui, attrs \\ %{}) do
    poui
    |> PendingOui.changeset(attrs)
    |> Repo.update!()
  end
end
