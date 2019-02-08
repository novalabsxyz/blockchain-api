defmodule BlockchainAPI.TxnManager do

  def submit(txn0) do

    txn = txn0 |> Base.decode64! |> :blockchain_txn.deserialize()

    case :blockchain_txn.is_valid(txn) do
      true ->
        :blockchain_worker.submit_txn(txn)
      false ->
        {:error, "invalid_txn"}
    end

  end

end
