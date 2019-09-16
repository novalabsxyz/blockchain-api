defmodule RewardsNotifierTest do
  use BlockchainAPI.DataCase

  alias BlockchainAPI.{
    Repo,
    RewardsNotifier
  }

  alias BlockchainAPI.Schema.{
    Account,
    Block,
    RewardsTransaction,
    RewardTxn,
    Transaction
  }

  describe "send_notifications/0" do
    setup do
      account =
        Repo.insert!(%Account{
          name: "account0",
          balance: 100,
          address: "address0",
          fee: 1,
          nonce: 0
        })

      block = Repo.insert!(%Block{height: 1, hash: "hash1", round: 1, time: 1})

      transaction =
        Repo.insert!(%Transaction{
          hash: :crypto.strong_rand_bytes(32),
          type: "reward_txn",
          status: "cleared",
          block_height: block.height
        })

      rewards_transaction = Repo.insert!(%RewardsTransaction{fee: 1, hash: transaction.hash})

      Repo.insert!(%RewardTxn{
        account: account.address,
        gateway: "gateway1",
        amount: 23,
        rewards_hash: rewards_transaction.hash,
        type: "reward_txn"
      })

      :ok
    end

    test "notifier client succesfully sends reward txns and reschedules" do
      resp = RewardsNotifier.send_notifications()
      assert {:ok, _ref} = resp
    end
  end
end
