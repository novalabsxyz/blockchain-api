defmodule BlockchainAPI.Query.POCReceiptsTransactionTest do
  @moduledoc false

  use BlockchainAPI.DataCase
  import BlockchainAPI.TestHelpers

  alias BlockchainAPI.Query.POCReiptsTransaction

  setup do
    insert_fake_challenges()
    :ok
  end

  test "returns challenges issued" do
    assert POCReceiptsTransaction.issued() == 1000
  end
end
