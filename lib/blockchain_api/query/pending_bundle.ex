defmodule BlockchainAPI.Query.PendingBundle do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.PendingBundle}

  def create(attrs \\ %{}) do
    %PendingBundle{}
    |> PendingBundle.changeset(attrs)
    |> Repo.insert()
  end

  def get!(hash) do
    PendingBundle
    |> where([pbundle], pbundle.hash == ^hash)
    |> Repo.one!()
  end

  def get_by_id!(id) do
    PendingBundle
    |> where([pbundle], pbundle.id == ^id)
    |> Repo.one!()
  end

  def update!(pbundle, attrs \\ %{}) do
    pbundle
    |> PendingBundle.changeset(attrs)
    |> Repo.update!()
  end
end
