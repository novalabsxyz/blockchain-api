defmodule BlockchainAPI.Committer do
  @moduledoc false

  alias BlockchainAPI.Repo
  alias BlockchainAPI.{
    Repo,
    Explorer,
    Explorer.Block,
    Explorer.Transaction,
    Explorer.GatewayTransaction,
    Explorer.PaymentTransaction,
    Explorer.LocationTransaction,
    Explorer.CoinbaseTransaction,
    Explorer.AccountTransaction
  }
  alias BlockchainAPIWeb.{BlockChannel, AccountChannel}

  def commit(block, chain) do
    Repo.transaction(fn() ->

      {:ok, inserted_block} = block
                              |> Block.map()
                              |> Explorer.create_block()
      add_accounts(block, chain)
      add_transactions(block)
      add_account_transactions(block)
      # NOTE: move this elsewhere...
      BlockChannel.broadcast_change(inserted_block)
    end)
  end

  #==================================================================
  # Add all accounts
  #==================================================================
  defp add_accounts(block, chain) do
    # NOTE: A block may contain multiple transactions of different types
    # There could also be multiple transactions made from the same account address
    # Since this is just add_accounts, and address is a primary key, I think it's probably
    # fine to add it directly, BUT the balance needs to be updated at the end for the account
    # and so does the transaction fee
    ledger = :blockchain.ledger(chain)
    {:ok, fee} = :blockchain_ledger_v1.transaction_fee(ledger)

    case :blockchain_block.transactions(block) do
      [] ->
        :ok
      txns ->
        Enum.map(txns,
          fn txn ->
            case :blockchain_txn.type(txn) do
              :blockchain_txn_coinbase_v1 ->
                {:ok, account} = upsert_account(:blockchain_txn_coinbase_v1, txn, ledger)
                # NOTE: move this elsewhere...
                AccountChannel.broadcast_change(account)
              :blockchain_txn_payment_v1 ->
                {:ok, account} = upsert_account(:blockchain_txn_payment_v1, txn, ledger)
                # NOTE: move this elsewhere...
                AccountChannel.broadcast_change(account)
              _ ->
                :ok
            end
          end)
    end

    # NOTE: We'd have added whatever accounts were added/updated for this block at this point
    # It should be "safe" to update the transaction fee for each account from the ledger
    Enum.map(
      Explorer.list_all_accounts(),
      fn account ->
        Explorer.update_account(account, %{fee: fee})
      end)
  end

  #==================================================================
  # Upsert account from transactions
  #==================================================================

  defp upsert_account(:blockchain_txn_coinbase_v1, txn, ledger) do
    addr = :blockchain_txn_coinbase_v1.payee(txn)
    {:ok, entry} = :blockchain_ledger_v1.find_entry(addr, ledger)
    try do
      account = Explorer.get_account!(addr)
      account_map =
        %{balance: :blockchain_ledger_entry_v1.balance(entry),
          nonce: :blockchain_ledger_entry_v1.nonce(entry)}
      Explorer.update_account(account, account_map)
    rescue
      _error in Ecto.NoResultsError ->
        account_map =
          %{address: addr,
            balance: :blockchain_ledger_entry_v1.balance(entry),
            nonce: :blockchain_ledger_entry_v1.nonce(entry)}
        Explorer.create_account(account_map)
    end
  end

  defp upsert_account(:blockchain_txn_payment_v1, txn, ledger) do
    payee = :blockchain_txn_payment_v1.payee(txn)
    payer = :blockchain_txn_payment_v1.payer(txn)
    {:ok, payee_entry} = :blockchain_ledger_v1.find_entry(payee, ledger)
    {:ok, payer_entry} = :blockchain_ledger_v1.find_entry(payer, ledger)
    try do
      payer_account = Explorer.get_account!(payer)
      payer_map =
        %{balance: :blockchain_ledger_entry_v1.balance(payer_entry),
          nonce: :blockchain_ledger_entry_v1.nonce(payer_entry)}
      Explorer.update_account(payer_account, payer_map)
    rescue
      _error in Ecto.NoResultsError ->
        payer_map =
          %{address: payer,
            balance: :blockchain_ledger_entry_v1.balance(payer_entry),
            nonce: :blockchain_ledger_entry_v1.nonce(payer_entry)}
        Explorer.create_account(payer_map)
    end
    try do
      payee_account = Explorer.get_account!(payee)
      payee_map =
        %{balance: :blockchain_ledger_entry_v1.balance(payee_entry),
          nonce: :blockchain_ledger_entry_v1.nonce(payee_entry)}
      Explorer.update_account(payee_account, payee_map)
    rescue
      _error in Ecto.NoResultsError ->
        payee_map =
          %{address: payee,
            balance: :blockchain_ledger_entry_v1.balance(payee_entry),
            nonce: :blockchain_ledger_entry_v1.nonce(payee_entry)}
        Explorer.create_account(payee_map)
    end
  end

  #==================================================================
  # Add all transactions
  #==================================================================
  defp add_transactions(block) do
    height = :blockchain_block.height(block)
    case :blockchain_block.transactions(block) do
      [] ->
        :ok
      txns ->
        Enum.map(txns, fn txn ->
          case :blockchain_txn.type(txn) do
            :blockchain_txn_coinbase_v1 -> insert_transaction(:blockchain_txn_coinbase_v1, txn, height)
            :blockchain_txn_payment_v1 -> insert_transaction(:blockchain_txn_payment_v1, txn, height)
            :blockchain_txn_add_gateway_v1 -> insert_transaction(:blockchain_txn_add_gateway_v1, txn, height)
            :blockchain_txn_assert_location_v1 -> insert_transaction(:blockchain_txn_assert_location_v1, txn, height)
            _ ->
              :ok
          end
        end)
    end
  end

  #==================================================================
  # Insert individual transactions
  #==================================================================
  defp insert_transaction(:blockchain_txn_coinbase_v1, txn, height) do
    {:ok, transaction_entry} = Explorer.create_transaction(height, Transaction.map(:blockchain_txn_coinbase_v1, txn))
    Explorer.create_coinbase(transaction_entry.hash, CoinbaseTransaction.map(txn))
  end

  defp insert_transaction(:blockchain_txn_payment_v1, txn, height) do
    {:ok, transaction_entry} = Explorer.create_transaction(height, Transaction.map(:blockchain_txn_payment_v1, txn))
    Explorer.create_payment(transaction_entry.hash, PaymentTransaction.map(txn))
  end

  defp insert_transaction(:blockchain_txn_add_gateway_v1, txn, height) do
    {:ok, transaction_entry} = Explorer.create_transaction(height, Transaction.map(:blockchain_txn_add_gateway_v1, txn))
    Explorer.create_gateway(transaction_entry.hash, GatewayTransaction.map(txn))
  end

  defp insert_transaction(:blockchain_txn_assert_location_v1, txn, height) do
    {:ok, transaction_entry} = Explorer.create_transaction(height, Transaction.map(:blockchain_txn_assert_location_v1, txn))
    Explorer.create_location(transaction_entry.hash, LocationTransaction.map(txn))
  end

  #==================================================================
  # Add all account transactions
  #==================================================================
  defp add_account_transactions(block) do
    case :blockchain_block.transactions(block) do
      [] ->
        :ok
      txns ->
        Enum.map(txns, fn txn ->
          case :blockchain_txn.type(txn) do
            :blockchain_txn_coinbase_v1 -> insert_account_transaction(:blockchain_txn_coinbase_v1, txn)
            :blockchain_txn_payment_v1 -> insert_account_transaction(:blockchain_txn_payment_v1, txn)
            :blockchain_txn_add_gateway_v1 -> insert_account_transaction(:blockchain_txn_add_gateway_v1, txn)
            :blockchain_txn_assert_location_v1 -> insert_account_transaction(:blockchain_txn_assert_location_v1, txn)
            _ -> :ok
          end
        end)
    end
  end

  #==================================================================
  # Insert account transactions
  #==================================================================
  defp insert_account_transaction(:blockchain_txn_coinbase_v1, txn) do
    try do
      account = Explorer.get_account!(:blockchain_txn_coinbase_v1.payee(txn))
      txn = Explorer.get_transaction!(:blockchain_txn_coinbase_v1.hash(txn))
      Explorer.create_account_transaction(AccountTransaction.map(account, txn))
    rescue
      _error in Ecto.NoResultsError ->
        {:error, "No associated account for coinbase transaction"}
    end
  end

  defp insert_account_transaction(:blockchain_txn_payment_v1, txn) do
    try do
      account = Explorer.get_account!(:blockchain_txn_payment_v1.payee(txn))
      txn = Explorer.get_transaction!(:blockchain_txn_payment_v1.hash(txn))
      Explorer.create_account_transaction(AccountTransaction.map(account, txn))
    rescue
      _error in Ecto.NoResultsError ->
        {:error, "No associated payee account for payment transaction"}
    end
    try do
      account = Explorer.get_account!(:blockchain_txn_payment_v1.payer(txn))
      txn = Explorer.get_transaction!(:blockchain_txn_payment_v1.hash(txn))
      Explorer.create_account_transaction(AccountTransaction.map(account, txn))
    rescue
      _error in Ecto.NoResultsError ->
        {:error, "No associated payer account for payment transaction"}
    end
  end

  defp insert_account_transaction(:blockchain_txn_add_gateway_v1, txn) do
    try do
      account = Explorer.get_account!(:blockchain_txn_add_gateway_v1.owner(txn))
      txn = Explorer.get_transaction!(:blockchain_txn_add_gateway_v1.hash(txn))
      Explorer.create_account_transaction(AccountTransaction.map(account, txn))
    rescue
      _error in Ecto.NoResultsError ->
        {:error, "No associated account for coinbase transaction"}
    end
  end

  defp insert_account_transaction(:blockchain_txn_assert_location_v1, txn) do
    try do
      account = Explorer.get_account!(:blockchain_txn_assert_location_v1.owner(txn))
      txn = Explorer.get_transaction!(:blockchain_txn_assert_location_v1.hash(txn))
      Explorer.create_account_transaction(AccountTransaction.map(account, txn))
    rescue
      _error in Ecto.NoResultsError ->
        {:error, "No associated account for coinbase transaction"}
    end
  end
end
