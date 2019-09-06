defmodule BlockchainAPI.Query.StatsTest do
  use BlockchainAPI.DataCase

  alias BlockchainAPI.Query.Stats
  alias BlockchainAPI.Util
  import BlockchainAPI.TestHelpers

  describe "supply" do
    test "get_supply/0 returns the total token supply" do
      account1 = account_fixture(%{balance: 2, address: "address1"})
      account2 = account_fixture(%{balance: 5, address: "address2"})
      assert Stats.get_supply() == account1.balance + account2.balance
    end
  end

  describe "block time" do
    test "get_block_time/1 given 24h shift returns avg block times" do
      block_fixture(%{time: Util.shifted_unix_time(seconds: -60), height: 3})
      block_fixture(%{time: Util.shifted_unix_time(seconds: -125), height: 2})
      block_fixture(%{time: Util.shifted_unix_time(seconds: -230), height: 1})
      # intervals: 65, 105
      # avg: 85
      assert Stats.get_block_time(hours: -24) == 85.0
    end
  end
end
