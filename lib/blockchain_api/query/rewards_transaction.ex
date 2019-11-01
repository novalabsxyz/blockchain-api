defmodule BlockchainAPI.Query.RewardsTransaction do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{
    Repo,
    Schema.RewardsTransaction,
    Schema.RewardTxn,
    Schema.Transaction,
    Util
  }

  def create(attrs \\ %{}) do
    %RewardsTransaction{}
    |> RewardsTransaction.changeset(attrs)
    |> Repo.insert()
  end

  def get!(hash) do
    RewardsTransaction
    |> where([rewards_txn], rewards_txn.hash == ^hash)
    |> preload([:reward_txns])
    |> Repo.one!()
  end

  def list(_params) do
    from(r in RewardsTransaction, preload: [:reward_txns]) |> Repo.all()
  end

  def list_for(account_addr) do
    from(
      r in RewardsTransaction,
      left_join: rt in RewardTxn,
      on: r.hash == rt.rewards_hash,
      left_join: t in Transaction,
      on: r.hash == t.hash,
      where: rt.account == ^account_addr,
      order_by: [desc: rt.id],
      select: %{
        hotspot: rt.gateway,
        account: rt.account,
        amount: rt.amount,
        type: rt.type,
        hash: t.hash,
        height: t.block_height
      }
    )
    |> Repo.all()
    |> encode()
  end

  defp encode([]), do: []
  defp encode(list) do
    list |> Enum.map(&encode_entry/1)
  end

  defp encode_entry(%{hotspot: g, account: a, hash: h}=map) do
    %{map | hotspot: Util.bin_to_string(g), account: Util.bin_to_string(a), hash: Util.bin_to_string(h)}
  end

end
