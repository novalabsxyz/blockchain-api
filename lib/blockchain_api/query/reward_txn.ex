defmodule BlockchainAPI.Query.RewardTxn do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.RewardTxn}

  def create(attrs \\ %{}) do
    %RewardTxn{}
    |> RewardTxn.changeset(attrs)
    |> Repo.insert()
  end

  def get!(rewards_hash, account, type) do
    from(
      r in RewardTxn,
      where: r.rewards_hash == ^rewards_hash,
      where: r.account == ^account,
      where: r.type == ^type
    )
    |> Repo.one!()
  end


end
