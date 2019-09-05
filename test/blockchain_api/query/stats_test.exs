defmodule BlockchainAPI.Query.StatsTest do
  use BlockchainAPI.DataCase

  alias BlockchainAPI.Query.Stats
  import BlockchainAPI.TestHelpers

  describe "supply" do
    test "get_supply/0 returns the total token supply" do
      account1 = account_fixture(%{balance: 2, address: "address1"})
      account2 = account_fixture(%{balance: 5, address: "address2"})
      assert Stats.get_supply() == account1.balance + account2.balance
    end
  end
end
