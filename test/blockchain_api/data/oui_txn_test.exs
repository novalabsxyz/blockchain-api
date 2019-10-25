defmodule BlockchainAPI.Test.Data.OUITxn do
  import BlockchainAPI.Test.Factory
  use BlockchainAPI.DataCase
  alias BlockchainAPI.Query

  test "oui txn insert" do
    1..200
    |> Enum.map(
      fn(_) ->
          txn = insert(:transaction, %{type: "oui"})
          _oui_txn = insert(:oui_transaction, %{txn: txn})
      end)

    queried = Query.OUITransaction.list(%{})
    assert length(queried) == 200
  end
end
