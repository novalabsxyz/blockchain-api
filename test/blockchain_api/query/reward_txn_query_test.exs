defmodule BlockchainAPI.Query.RewardTxnTest do
  use BlockchainAPI.DataCase

  alias BlockchainAPI.Query
  alias BlockchainAPI.Schema.{Account, Block, RewardsTransaction, RewardTxn, Transaction}

  setup do
    account = Repo.insert!(%Account{name: "account1", balance: 100, address: "address1", fee: 1, nonce: 1})
    block = Repo.insert!(%Block{height: 1, hash: "hash1", round: 1, time: 1})
    transaction = Repo.insert!(%Transaction{hash: "hash1", type: "reward_txn", status: "cleared", block_height: block.height})
    rewards_transaction = Repo.insert!(%RewardsTransaction{fee: 1, hash: transaction.hash})
    reward_txn = Repo.insert!(%RewardTxn{account: account.address, gateway: "gateway1", amount: 23, rewards_hash: rewards_transaction.hash, type: "reward_txn"})
    {:ok, %{reward_txn: reward_txn, account: account}}
  end

  describe "get_from_last_week/0" do
    test "returns sum of rewards from last week", %{reward_txn: reward_txn, account: account} do
      [txn] = Query.RewardTxn.get_from_last_week()
      assert txn.account == account.address
      assert txn.amount == Decimal.new(reward_txn.amount)
    end
  end
end
