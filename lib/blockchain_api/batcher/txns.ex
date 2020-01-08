defmodule BlockchainAPI.Batcher.Txns do
  @moduledoc false

  alias BlockchainAPI.{Query, Schema.Transaction}

  # ==================================================================
  # Add all transactions
  # ==================================================================
  def insert_all(block, _ledger, height) do
    case :blockchain_block.transactions(block) do
      [] ->
        {:ok, :no_txns}

      txns ->
        txns_to_insert =
          Enum.reduce(txns, [], fn(txn, acc) ->
            case :blockchain_txn.type(txn) do
              :blockchain_txn_coinbase_v1 ->
                to_insert = Transaction.map(:blockchain_txn_coinbase_v1, txn)
                [to_insert | acc]

              :blockchain_txn_payment_v1 ->
                to_insert = Transaction.map(:blockchain_txn_payment_v1, txn)
                [to_insert | acc]

              :blockchain_txn_add_gateway_v1 ->
                to_insert = Transaction.map(:blockchain_txn_add_gateway_v1, txn)
                [to_insert | acc]

              :blockchain_txn_gen_gateway_v1 ->
                to_insert = Transaction.map(:blockchain_txn_gen_gateway_v1, txn)
                [to_insert | acc]

              :blockchain_txn_poc_request_v1 ->
                to_insert = Transaction.map(:blockchain_txn_poc_request_v1, txn)
                [to_insert | acc]

              :blockchain_txn_poc_receipts_v1 ->
                to_insert = Transaction.map(:blockchain_txn_poc_receipts_v1, txn)
                [to_insert | acc]

              :blockchain_txn_assert_location_v1 ->
                to_insert = Transaction.map(:blockchain_txn_assert_location_v1, txn)
                [to_insert | acc]

              :blockchain_txn_security_coinbase_v1 ->
                to_insert = Transaction.map(:blockchain_txn_security_coinbase_v1, txn)
                [to_insert | acc]

              :blockchain_txn_security_exchange_v1 ->
                to_insert = Transaction.map(:blockchain_txn_security_exchange_v1, txn)
                [to_insert | acc]

              :blockchain_txn_dc_coinbase_v1 ->
                to_insert = Transaction.map(:blockchain_txn_dc_coinbase_v1, txn)
                [to_insert | acc]

              :blockchain_txn_consensus_group_v1 ->
                to_insert = Transaction.map(:blockchain_txn_consensus_group_v1, txn)
                [to_insert | acc]

              :blockchain_txn_rewards_v1 ->
                to_insert = Transaction.map(:blockchain_txn_rewards_v1, txn)
                [to_insert | acc]

              :blockchain_txn_oui_v1 ->
                to_insert = Transaction.map(:blockchain_txn_oui_v1, txn)
                [to_insert | acc]

                _ ->
                acc
            end
          end)
          |> Enum.sort_by(fn(txn) -> txn.type end)

        Query.Transaction.insert_all(height, txns_to_insert)
    end
  end
end
