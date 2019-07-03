defmodule BlockchainAPI.Query.RewardsTransaction do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.RewardsTransaction}

  def create(attrs \\ %{}) do
    %RewardsTransaction{}
    |> RewardsTransaction.changeset(attrs)
    |> Repo.insert()
  end

  def get!(hash) do
    RewardsTransaction
    |> where([rewards_txn], rewards_txn.hash == ^hash)
    |> preload([:reward_txns])
    |> Repo.one!
  end

  def list(_params) do
    from(r in RewardsTransaction, preload: [:reward_txns]) |> Repo.all()
  end
end
