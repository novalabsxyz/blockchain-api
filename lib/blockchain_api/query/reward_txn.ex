defmodule BlockchainAPI.Query.RewardTxn do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.RewardTxn, Schema.Transaction, Schema.Block}

  def create(attrs \\ %{}) do
    %RewardTxn{}
    |> RewardTxn.changeset(attrs)
    |> Repo.insert()
  end

  def get!(rewards_hash, account, type) do
    from(
      r in RewardTxn,
      left_join: t in Transaction,
      on: t.hash == ^rewards_hash,
      left_join: b in Block,
      on: t.block_height == b.height,
      where: r.rewards_hash == ^rewards_hash,
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

  def get_from_last_week do
    Timex.now()
    |> Timex.shift(days: -7)
    |> get_after()
  end

  def get_after(time) do
    from(
      rt in RewardTxn,
      where: rt.inserted_at > ^time,
      group_by: rt.account,
      select: %{
        account: rt.account,
        amount: sum(rt.amount)
      }
    )
    |> Repo.all()
  end

  def total_by_epoch(hash) do
    from(
      t in RewardsTransaction,
      left_join: r in RewardTxn,
      on: r.rewards_hash == t.hash,
      where: t.hash == ^hash,
      select: sum(r.amount)
    )
    |> Repo.one()
  end

end
