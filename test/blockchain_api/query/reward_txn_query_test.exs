defmodule BlockchainAPI.Query.RewardTxnTest do
  use BlockchainAPI.DataCase

  alias BlockchainAPI.Query
  alias BlockchainAPI.Schema.{Account, Block, RewardsTransaction, RewardTxn, Transaction}

  setup do
    account = Repo.insert!(%Account{name: "account0", balance: 100, address: "address0", fee: 1, nonce: 0})
    block = Repo.insert!(%Block{height: 1, hash: "hash1", round: 1, time: 1})

    {:ok, %{account: account, block: block, reward_txn: insert_reward_txn(account, block)}}
  end

  describe "get_from_last_week/0" do
    test "returns sum of rewards from last week", %{account: account, block: block, reward_txn: reward_txn0} do
      reward_txn1 = insert_reward_txn(account, block)
      [reward] = Query.RewardTxn.get_from_last_week()

      assert reward.account == account.address
      assert reward.amount == Decimal.new(reward_txn0.amount + reward_txn1.amount)
    end

    test "returns sum of rewards for multiple accounts", %{account: account0, block: block, reward_txn: reward_txn0} do
      account1 = Repo.insert!(%Account{name: "account1", balance: 300, address: "address1", fee: 1, nonce: 1})
      reward_txn1 = insert_reward_txn(account1, block)
      [reward0, reward1] = Query.RewardTxn.get_from_last_week() |> Enum.sort(&(&1.account < &2.account))

      assert reward0.account == account0.address
      assert reward0.amount == Decimal.new(reward_txn0.amount)
      assert reward1.account == account1.address
      assert reward1.amount == Decimal.new(reward_txn1.amount)
    end

    test "doesn't returns rewards from over a week ago", %{account: account, reward_txn: reward_txn1} do
      block0 = Repo.insert!(%Block{height: 0, hash: "hash0", round: 0, time: 0})
      reward_txn0 = insert_reward_txn(account, block0, Timex.now() |> Timex.shift(days: -8) |> Timex.to_naive_datetime() |> NaiveDateTime.truncate(:second))
      [reward] = Query.RewardTxn.get_from_last_week()

      assert reward.account == account.address
      assert reward.amount == Decimal.new(reward_txn1.amount)
    end
  end

  defp insert_reward_txn(account, block) do
    insert_reward_txn(account, block, Timex.now() |> Timex.to_naive_datetime() |> NaiveDateTime.truncate(:second))
  end
  defp insert_reward_txn(account, block, date) do
    transaction = Repo.insert!(%Transaction{hash: :crypto.strong_rand_bytes(32), type: "reward_txn", status: "cleared", block_height: block.height})
    rewards_transaction = Repo.insert!(%RewardsTransaction{fee: 1, hash: transaction.hash})
    Repo.insert!(%RewardTxn{account: account.address, gateway: "gateway1", amount: 23, rewards_hash: rewards_transaction.hash, type: "reward_txn", inserted_at: date})
  end
end
