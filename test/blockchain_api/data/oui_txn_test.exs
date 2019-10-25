defmodule BlockchainAPI.Test.Data.OUITxn do
  import BlockchainAPI.Test.Factory
  use BlockchainAPI.DataCase
  alias BlockchainAPI.Query

  test "single oui insert" do
    txn = insert(:transaction, %{type: "oui"})
    _oui_txn = insert(:oui_transaction, %{txn: txn})
    queried = Query.OUITransaction.list(%{})
    assert length(queried) == 1
  end

  test "multiple oui insert" do

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
