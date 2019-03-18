defmodule BlockchainAPI.Committer do
  @moduledoc false

  alias BlockchainAPI.{
    Repo,
    Query,
    Schema.Block,
    Schema.Transaction,
    Schema.GatewayTransaction,
    Schema.PaymentTransaction,
    Schema.LocationTransaction,
    Schema.CoinbaseTransaction,
    Schema.AccountTransaction,
    Schema.AccountBalance,
    Schema.Hotspot,
    Util
  }
  alias BlockchainAPIWeb.{BlockChannel, AccountChannel}

  require Logger

  def commit(block, chain) do
    # NOTE: the block commit _needs_ to happen as a single DB transaction
    # to ensure consistency
    commit_block(block, chain)
    # This is extra information that we're gathering just for the application
    commit_account_balances(block, chain)
  end

  defp commit_block(block, chain) do
    block_txn =
      Repo.transaction(fn() ->

        {:ok, inserted_block} = block
                                |> Block.map()
                                |> Query.Block.create()
        add_accounts(block, chain)
        add_transactions(block)
        add_account_transactions(block)
        # NOTE: move this elsewhere...
        BlockChannel.broadcast_change(inserted_block)
      end)

    case block_txn do
      {:ok, term} ->
        Logger.info("Successfully committed block at height: #{:blockchain_block.height(block)} to db!")
        {:ok, term}
      {:error, reason} ->
        Logger.error("Failed to commit block at height: #{:blockchain_block.height(block)}")
        {:error, reason}
    end
  end

  defp commit_account_balances(block, chain) do
    account_bal_txn =
      Repo.transaction(fn() ->
        add_account_balances(block, chain)
      end)

    case account_bal_txn do
      {:ok, term} ->
        Logger.info("Successfully committed account_balances at height: #{:blockchain_block.height(block)} to db!")
        {:ok, term}
      {:error, reason} ->
        Logger.info("Failed to commit account_balances at height: #{:blockchain_block.height(block)} to db!")
        {:error, reason}
    end
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
    Query.Account.update_all_fee(fee)
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
            :blockchain_txn_gen_gateway_v1 -> insert_transaction(:blockchain_txn_gen_gateway_v1, txn, height)
            :blockchain_txn_assert_location_v1 ->
              insert_transaction(:blockchain_txn_assert_location_v1, txn, height)
              # also upsert hotspot
              upsert_hotspot(txn)
            _ ->
              :ok
          end
        end)
    end
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
            :blockchain_txn_gen_gateway_v1 -> insert_account_transaction(:blockchain_txn_gen_gateway_v1, txn)
            _ -> :ok
          end
        end)
    end
  end

  #==================================================================
  # Add all account balances (if there is a change)
  #==================================================================
  defp add_account_balances(block, chain) do
    chain
    |> :blockchain.ledger()
    |> :blockchain_ledger_v1.entries()
    |> Enum.map(fn {address, entry} ->
      try do
        ledger_entry_balance = :blockchain_ledger_entry_v1.balance(entry)
        case Query.AccountBalance.get_latest!(address) do
          nil ->
            AccountBalance.map(address, ledger_entry_balance, block, ledger_entry_balance)
            |> Query.AccountBalance.create()
          account_entry ->
            account_entry_balance = account_entry.balance
            case account_entry_balance == ledger_entry_balance do
              true ->
                :ok
              false ->
                AccountBalance.map(address, ledger_entry_balance, block, (ledger_entry_balance - account_entry_balance))
                |> Query.AccountBalance.create()
            end
        end
      rescue
        _error in Ecto.NoResultsError ->
          ledger_entry_balance = :blockchain_ledger_entry_v1.balance(entry)
          AccountBalance.map(address, ledger_entry_balance, block, ledger_entry_balance)
          |> Query.AccountBalance.create()
      end
    end)
  end

  #==================================================================
  # Upsert account from transactions
  #==================================================================

  defp upsert_account(:blockchain_txn_coinbase_v1, txn, ledger) do
    addr = :blockchain_txn_coinbase_v1.payee(txn)
    {:ok, entry} = :blockchain_ledger_v1.find_entry(addr, ledger)
    try do
      account = Query.Account.get!(addr)
      account_map =
        %{balance: :blockchain_ledger_entry_v1.balance(entry),
          nonce: :blockchain_ledger_entry_v1.nonce(entry)}
      account = Query.Account.update!(account, account_map)
      {:ok, account}
    rescue
      _error in Ecto.NoResultsError ->
        account_map =
          %{address: addr,
            balance: :blockchain_ledger_entry_v1.balance(entry),
            nonce: :blockchain_ledger_entry_v1.nonce(entry)}
        Query.Account.create(account_map)
    end
  end

  defp upsert_account(:blockchain_txn_payment_v1, txn, ledger) do
    payee = :blockchain_txn_payment_v1.payee(txn)
    payer = :blockchain_txn_payment_v1.payer(txn)
    {:ok, payee_entry} = :blockchain_ledger_v1.find_entry(payee, ledger)
    {:ok, payer_entry} = :blockchain_ledger_v1.find_entry(payer, ledger)
    try do
      payer_account = Query.Account.get!(payer)
      payer_map =
        %{balance: :blockchain_ledger_entry_v1.balance(payer_entry),
          nonce: :blockchain_ledger_entry_v1.nonce(payer_entry)}
      account = Query.Account.update!(payer_account, payer_map)
      {:ok, account}
    rescue
      _error in Ecto.NoResultsError ->
        payer_map =
          %{address: payer,
            balance: :blockchain_ledger_entry_v1.balance(payer_entry),
            nonce: :blockchain_ledger_entry_v1.nonce(payer_entry)}
        Query.Account.create(payer_map)
    end
    try do
      payee_account = Query.Account.get!(payee)
      payee_map =
        %{balance: :blockchain_ledger_entry_v1.balance(payee_entry),
          nonce: :blockchain_ledger_entry_v1.nonce(payee_entry)}
      account = Query.Account.update!(payee_account, payee_map)
      {:ok, account}
    rescue
      _error in Ecto.NoResultsError ->
        payee_map =
          %{address: payee,
            balance: :blockchain_ledger_entry_v1.balance(payee_entry),
            nonce: :blockchain_ledger_entry_v1.nonce(payee_entry)}
        Query.Account.create(payee_map)
    end
  end


  #==================================================================
  # Insert individual transactions
  #==================================================================
  defp insert_transaction(:blockchain_txn_coinbase_v1, txn, height) do
    {:ok, transaction_entry} = Query.Transaction.create(height, Transaction.map(:blockchain_txn_coinbase_v1, txn))
    Query.CoinbaseTransaction.create(transaction_entry.hash, CoinbaseTransaction.map(txn))
  end

  defp insert_transaction(:blockchain_txn_payment_v1, txn, height) do
    {:ok, transaction_entry} = Query.Transaction.create(height, Transaction.map(:blockchain_txn_payment_v1, txn))
    Query.PaymentTransaction.create(transaction_entry.hash, PaymentTransaction.map(txn))
  end

  defp insert_transaction(:blockchain_txn_add_gateway_v1, txn, height) do
    {:ok, transaction_entry} = Query.Transaction.create(height, Transaction.map(:blockchain_txn_add_gateway_v1, txn))
    Query.GatewayTransaction.create(transaction_entry.hash, GatewayTransaction.map(txn))
  end

  defp insert_transaction(:blockchain_txn_gen_gateway_v1, txn, height) do
    {:ok, transaction_entry} = Query.Transaction.create(height, Transaction.map(:blockchain_txn_gen_gateway_v1, txn))
    Query.GatewayTransaction.create(transaction_entry.hash, GatewayTransaction.map(:genesis, txn))
  end

  defp insert_transaction(:blockchain_txn_assert_location_v1, txn, height) do
    {:ok, transaction_entry} = Query.Transaction.create(height, Transaction.map(:blockchain_txn_assert_location_v1, txn))
    Query.LocationTransaction.create(transaction_entry.hash, LocationTransaction.map(txn))
  end

  #==================================================================
  # Insert account transactions
  #==================================================================
  defp insert_account_transaction(:blockchain_txn_coinbase_v1, txn) do
    try do
      account = Query.Account.get!(:blockchain_txn_coinbase_v1.payee(txn))
      txn = Query.Transaction.get!(:blockchain_txn_coinbase_v1.hash(txn))
      Query.AccountTransaction.create(AccountTransaction.map(account, txn))
    rescue
      _error in Ecto.NoResultsError ->
        {:error, "No associated account for coinbase transaction"}
    end
  end

  defp insert_account_transaction(:blockchain_txn_payment_v1, txn) do
    try do
      account = Query.Account.get!(:blockchain_txn_payment_v1.payee(txn))
      txn = Query.Transaction.get!(:blockchain_txn_payment_v1.hash(txn))
      Query.AccountTransaction.create(AccountTransaction.map(account, txn))
    rescue
      _error in Ecto.NoResultsError ->
        {:error, "No associated payee account for payment transaction"}
    end
    try do
      account = Query.Account.get!(:blockchain_txn_payment_v1.payer(txn))
      txn = Query.Transaction.get!(:blockchain_txn_payment_v1.hash(txn))
      Query.AccountTransaction.create(AccountTransaction.map(account, txn))
    rescue
      _error in Ecto.NoResultsError ->
        {:error, "No associated payer account for payment transaction"}
    end
  end

  defp insert_account_transaction(:blockchain_txn_add_gateway_v1, txn) do
    try do
      account = Query.Account.get!(:blockchain_txn_add_gateway_v1.owner(txn))
      txn = Query.Transaction.get!(:blockchain_txn_add_gateway_v1.hash(txn))
      Query.AccountTransaction.create(AccountTransaction.map(account, txn))
    rescue
      _error in Ecto.NoResultsError ->
        {:error, "No associated account for gateway transaction"}
    end
  end

  defp insert_account_transaction(:blockchain_txn_gen_gateway_v1, txn) do
    try do
      account = Query.Account.get!(:blockchain_txn_gen_gateway_v1.owner(txn))
      txn = Query.Transaction.get!(:blockchain_txn_gen_gateway_v1.hash(txn))
      Query.AccountTransaction.create(AccountTransaction.map(account, txn))
    rescue
      _error in Ecto.NoResultsError ->
        {:error, "No associated account for gen_gateway transaction"}
    end
  end

  defp insert_account_transaction(:blockchain_txn_assert_location_v1, txn) do
    try do
      account = Query.Account.get!(:blockchain_txn_assert_location_v1.owner(txn))
      txn = Query.Transaction.get!(:blockchain_txn_assert_location_v1.hash(txn))
      Query.AccountTransaction.create(AccountTransaction.map(account, txn))
    rescue
      _error in Ecto.NoResultsError ->
        {:error, "No associated account for assert location transaction"}
    end
  end

  defp upsert_hotspot(txn) do
    try do
      gateway = :blockchain_txn_assert_location_v1.gateway(txn)
      loc = :blockchain_txn_assert_location_v1.location(txn)
      hotspot = Query.Hotspot.get!(gateway)

      case Util.reverse_geocode(loc) do
        {:ok, loc_info_map} ->
          Query.Hotspot.update!(hotspot, loc_info_map)
        error ->
          #XXX: Don't do anything when you cannot decode via the googleapi
          error
      end
    rescue
      _error in Ecto.NoResultsError ->
        # No hotspot entry exists in the hotspot table
        case Hotspot.map(txn) do
          {:error, _}=error ->
            #XXX: Don't add it if googleapi failed?
            error
          map ->
            Query.Hotspot.create(map)
        end
    end
  end

end
