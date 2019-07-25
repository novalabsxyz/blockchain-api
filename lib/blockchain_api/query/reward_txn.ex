defmodule BlockchainAPI.Query.RewardTxn do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.RewardTxn, Schema.Transaction, Schema.Block}

  def create(attrs \\ %{}) do
    %RewardTxn{}
    |> RewardTxn.changeset(attrs)
    |> Repo.insert()
  end

  def get!(<<rewards_hash :: binary-size(32), _rest :: binary>>=unique_hash, account, type) do
    from(
      r in RewardTxn,
      left_join: t in Transaction,
      on: t.hash == ^rewards_hash,
      left_join: b in Block,
      on: t.block_height == b.height,
      where: r.unique_hash == ^unique_hash,
      where: r.account == ^account,
      where: r.type == ^type,
      distinct: t.block_height,
      select: %{
        block_height: t.block_height,
        block_time: b.time,
        account: r.account,
        gateway: r.gateway,
        amount: r.amount,
        type: r.type,
        rewards_hash: t.hash
      }
    )
    |> Repo.one!()
  end
end
