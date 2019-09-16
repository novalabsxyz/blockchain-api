defmodule BlockchainAPI.Query.ConsensusMember do
  @moduledoc """
  Consensue member query functions.
  """

  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.ConsensusMember}

  @doc """
  List all consensus members within given `params`.

  TODO: actually enable `params`.
  """
  def list(_params) do
    ConsensusMember
    |> order_by([ct], desc: ct.id)
    |> Repo.all()
  end

  @doc false
  def create(attrs \\ %{}) do
    %ConsensusMember{}
    |> ConsensusMember.changeset(attrs)
    |> Repo.insert()
  end
end
