defmodule BlockchainAPI.Query.POCPathElement do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.POCPathElement}

  def list(_) do
    POCPathElement
    |> Repo.all()
  end

  def get!(challengee) do
    POCPathElement
    |> where([poc_path_element], poc_path_element.challengee == ^challengee)
    |> Repo.one!
  end

  def create(attrs \\ %{}) do
    %POCPathElement{}
    |> POCPathElement.changeset(attrs)
    |> Repo.insert()
  end
end
