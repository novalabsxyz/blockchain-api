defmodule BlockchainAPI.Committer do
  @moduledoc false

  alias BlockchainAPI.{
    Repo,
    Query,
    Util,
    Schema.Block,
    Schema.Transaction,
    Schema.GatewayTransaction,
    Schema.PaymentTransaction,
    Schema.LocationTransaction,
    Schema.CoinbaseTransaction,
    Schema.SecurityTransaction,
    Schema.POCRequestTransaction,
    Schema.AccountTransaction,
    Schema.AccountBalance,
    Schema.Hotspot,
    Schema.POCReceiptsTransaction,
    Schema.POCPathElement,
    Schema.POCReceipt,
    Schema.POCWitness,
    Schema.ElectionTransaction,
    Schema.ConsensusMember
  }
  alias BlockchainAPIWeb.{BlockChannel, AccountChannel}

  require Logger

  def commit(block, ledger) do
    # NOTE: the block commit _needs_ to happen as a single DB transaction
    # to ensure consistency
    commit_block(block, ledger)
    # This is extra information that we're gathering just for the application
    commit_account_balances(block, ledger)
  end

  defp commit_block(block, ledger) do
    block_txn =
      Repo.transaction(fn() ->

        {:ok, inserted_block} = block
                                |> Block.map()
                                |> Query.Block.create()
        add_accounts(block, ledger)
        add_transactions(block, ledger)
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

  defp commit_account_balances(block, ledger) do
    account_bal_txn =
      Repo.transaction(fn() ->
        add_account_balances(block, ledger)
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
  defp add_accounts(block, ledger) do
    # NOTE: A block may contain multiple transactions of different types
    # There could also be multiple transactions made from the same account address
    # Since this is just add_accounts, and address is a primary key, I think it's probably
    # fine to add it directly, BUT the balance needs to be updated at the end for the account
    # and so does the transaction fee
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
  defp add_transactions(block, ledger) do
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
            :blockchain_txn_poc_request_v1 -> insert_transaction(:blockchain_txn_poc_request_v1, txn, height, ledger)
            :blockchain_txn_poc_receipts_v1 -> insert_transaction(:blockchain_txn_poc_receipts_v1, txn, height, block, ledger)
            :blockchain_txn_assert_location_v1 ->
              insert_transaction(:blockchain_txn_assert_location_v1, txn, height)
              # also upsert hotspot
              upsert_hotspot(:blockchain_txn_assert_location_v1, txn)
            :blockchain_txn_security_coinbase_v1 -> insert_transaction(:blockchain_txn_security_coinbase_v1, txn, height)
            :blockchain_txn_consensus_group_v1 -> insert_transaction(:blockchain_txn_consensus_group_v1, txn, height)
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
            :blockchain_txn_security_coinbase_v1 -> insert_account_transaction(:blockchain_txn_security_coinbase_v1, txn)
            _ -> :ok
          end
        end)
    end
  end

  #==================================================================
  # Add all account balances (if there is a change)
  #==================================================================
  defp add_account_balances(block, ledger) do
    ledger
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
    amount = :blockchain_txn_payment_v1.amount(txn)

    # NOTE: It's possible that this is a brand new payee and hasn't appeared
    # on the ledger yet, we create a dummy entry for it to make the DB happy
    payee_entry =
      case :blockchain_ledger_v1.find_entry(payee, ledger) do
        {:ok, p} ->
          p
        {:error, :not_found} ->
          :blockchain_ledger_entry_v1.new(0, amount)
      end

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
    {:ok, _transaction_entry} = Query.Transaction.create(height, Transaction.map(:blockchain_txn_coinbase_v1, txn))
    {:ok, _} = Query.CoinbaseTransaction.create(CoinbaseTransaction.map(txn))
  end

  defp insert_transaction(:blockchain_txn_security_coinbase_v1, txn, height) do
    {:ok, _transaction_entry} = Query.Transaction.create(height, Transaction.map(:blockchain_txn_security_coinbase_v1, txn))
    {:ok, _} = Query.SecurityTransaction.create(SecurityTransaction.map(txn))
  end

  defp insert_transaction(:blockchain_txn_consensus_group_v1, txn, height) do
    {:ok, _transaction_entry} = Query.Transaction.create(height, Transaction.map(:blockchain_txn_consensus_group_v1, txn))
    {:ok, election_entry} = Query.ElectionTransaction.create(ElectionTransaction.map(txn))

    :ok = Enum.each(
      :blockchain_txn_consensus_group_v1.members(txn),
      fn(member) ->
        {:ok, _member_entry} = Query.ConsensusMember.create(ConsensusMember.map(election_entry.id, member))
      end)
  end

  defp insert_transaction(:blockchain_txn_payment_v1, txn, height) do
    {:ok, _transaction_entry} = Query.Transaction.create(height, Transaction.map(:blockchain_txn_payment_v1, txn))
    {:ok, _} = Query.PaymentTransaction.create(PaymentTransaction.map(txn))
  end

  defp insert_transaction(:blockchain_txn_add_gateway_v1, txn, height) do
    {:ok, _transaction_entry} = Query.Transaction.create(height, Transaction.map(:blockchain_txn_add_gateway_v1, txn))
    {:ok, _} = Query.GatewayTransaction.create(GatewayTransaction.map(txn))
  end

  defp insert_transaction(:blockchain_txn_assert_location_v1, txn, height) do
    {:ok, _transaction_entry} = Query.Transaction.create(height, Transaction.map(:blockchain_txn_assert_location_v1, txn))
    {:ok, _} = Query.LocationTransaction.create(LocationTransaction.map(:blockchain_txn_assert_location_v1, txn))
  end

  defp insert_transaction(:blockchain_txn_gen_gateway_v1, txn, height) do
    {:ok, _transaction_entry} = Query.Transaction.create(height, Transaction.map(:blockchain_txn_gen_gateway_v1, txn))

    {:ok, _} = Query.GatewayTransaction.create(GatewayTransaction.map(:genesis, txn))

    case :blockchain_txn_gen_gateway_v1.location(txn) do
      :undefined ->
        :ok
      _ ->
        {:ok, _} = Query.LocationTransaction.create(LocationTransaction.map(:blockchain_txn_gen_gateway_v1, txn))
        upsert_hotspot(:blockchain_txn_gen_gateway_v1, txn)
    end
  end

  defp insert_transaction(:blockchain_txn_poc_request_v1, txn, height, ledger) do
    {:ok, _transaction_entry} = Query.Transaction.create(height, Transaction.map(:blockchain_txn_poc_request_v1, txn))

    {:ok, challenger_info} = txn
                             |> :blockchain_txn_poc_request_v1.challenger()
                             |> :blockchain_ledger_v1.find_gateway_info(ledger)

    challenger_loc = challenger_info |> :blockchain_ledger_gateway_v1.location()
    challenger_owner = challenger_info |> :blockchain_ledger_gateway_v1.owner_address()

    {:ok, _poc_request_entry} = POCRequestTransaction.map(challenger_loc, challenger_owner, txn)
                                |> Query.POCRequestTransaction.create()
  end

  defp insert_transaction(:blockchain_txn_poc_receipts_v1, txn, height, block, ledger) do

    chain = :blockchain_worker.blockchain()

    challenger = :blockchain_txn_poc_receipts_v1.challenger(txn)
    secret = :blockchain_txn_poc_receipts_v1.secret(txn)
    onion = :blockchain_txn_poc_receipts_v1.onion_key_hash(txn)

    {:ok, gw_info} = :blockchain_ledger_v1.find_gateway_info(challenger, ledger)
    last_challenge = :blockchain_ledger_gateway_v1.last_poc_challenge(gw_info)
    {:ok, challenge_block} = :blockchain.get_block(last_challenge, chain)

    challenge_block_hash = :blockchain_block.hash_block(challenge_block)
    entropy = <<secret :: binary, challenge_block_hash :: binary, challenger :: binary>>

    challenge_block_height = :blockchain_block.height(challenge_block)
    block_height = :blockchain_block.height(block)

    new_chain = :blockchain.ledger(ledger, chain)
    {:ok, old_ledger} = :blockchain.ledger_at(:blockchain_block.height(challenge_block), new_chain)

    {target, _gateway} = :blockchain_poc_path.target(entropy, old_ledger, challenger)

    Logger.warn("challenge_block_height: #{challenge_block_height}")
    Logger.warn("block_height: #{block_height}")
    Logger.warn("height: #{height}")
    Logger.warn("target_address: #{Util.bin_to_string(target)}")
    {:ok, target_name} = :erl_angry_purple_tiger.animal_name(Util.bin_to_string(target))
    Logger.warn("target_name: #{target_name}")

    {:ok, challenger_info} = :blockchain_ledger_v1.find_gateway_info(challenger, old_ledger)
    challenger_loc = :blockchain_ledger_gateway_v1.location(challenger_info)
    challenger_owner = :blockchain_ledger_gateway_v1.owner_address(challenger_info)

    {:ok, _transaction_entry} = Query.Transaction.create(height, Transaction.map(:blockchain_txn_poc_receipts_v1, txn))

    poc_request = Query.POCRequestTransaction.get_by_onion(onion)

    {:ok, poc_receipt_txn_entry} = POCReceiptsTransaction.map(poc_request.id, challenger_loc, challenger_owner, txn)
                                   |> Query.POCReceiptsTransaction.create()

    txn
    |> :blockchain_txn_poc_receipts_v1.path()
    |> Enum.map(
      fn(element) when element != :undefined ->
        challengee = element |> :blockchain_poc_path_element_v1.challengee()
        res = challengee |> :blockchain_ledger_v1.find_gateway_info(old_ledger)

        case res do
          {:error, _} ->
            :ok

          {:ok, challengee_info} ->
            challengee_loc = :blockchain_ledger_gateway_v1.location(challengee_info)
            challengee_owner = :blockchain_ledger_gateway_v1.owner_address(challengee_info)
            is_primary = challengee == target

            Logger.warn("challengee: #{Util.bin_to_string(challengee)}")
            {:ok, challengee_name} = :erl_angry_purple_tiger.animal_name(Util.bin_to_string(challengee))
            Logger.warn("challengee_name: #{challengee_name}")

            {:ok, path_element_entry} = POCPathElement.map(poc_receipt_txn_entry.hash, challengee_loc, challengee_owner, is_primary, element)
                                        |> Query.POCPathElement.create()

            case :blockchain_poc_path_element_v1.receipt(element) do
              :undefined ->
                :ok
              receipt ->
                rx_gateway = receipt |> :blockchain_poc_receipt_v1.gateway()
                {:ok, rx_info} = rx_gateway |> :blockchain_ledger_v1.find_gateway_info(old_ledger)
                rx_loc = :blockchain_ledger_gateway_v1.location(rx_info)
                rx_owner = :blockchain_ledger_gateway_v1.owner_address(rx_info)

                {:ok, _poc_receipt} = POCReceipt.map(path_element_entry.id, rx_loc, rx_owner, receipt)
                                      |> Query.POCReceipt.create()
            end

            element
            |> :blockchain_poc_path_element_v1.witnesses()
            |> Enum.map(
              fn(witness) when witness != :undefined ->
                witness_gateway = witness |> :blockchain_poc_witness_v1.gateway()

                case :blockchain_ledger_v1.find_gateway_info(witness_gateway, old_ledger) do
                  {:error, _} ->
                    :ok
                  {:ok, wx_info} ->
                    wx_loc = :blockchain_ledger_gateway_v1.location(wx_info)
                    wx_owner = :blockchain_ledger_gateway_v1.owner_address(wx_info)

                    {:ok, _poc_witness} = POCWitness.map(path_element_entry.id, wx_loc, wx_owner, witness)
                                          |> Query.POCWitness.create()
                end
              end)
        end
      end)
  end

  #==================================================================
  # Insert account transactions
  #==================================================================
  defp insert_account_transaction(:blockchain_txn_coinbase_v1, txn) do
    hash = :blockchain_txn_coinbase_v1.hash(txn)
    try do
      _pending_account_txn = hash
                             |> Query.AccountTransaction.get_pending_txn!()
                             |> Query.AccountTransaction.delete_pending!(AccountTransaction.map_pending(:blockchain_txn_coinbase_v1, txn))
    rescue
      _error in Ecto.NoResultsError ->
        # nothing to do
        :ok
      _error in Ecto.StaleEntryError ->
        # nothing to do
        :ok
    end
    {:ok, _} = Query.AccountTransaction.create(AccountTransaction.map_cleared(:blockchain_txn_coinbase_v1, txn))
  end

  defp insert_account_transaction(:blockchain_txn_payment_v1, txn) do
    hash = :blockchain_txn_payment_v1.hash(txn)
    try do
      _pending_account_txn = hash
                             |> Query.AccountTransaction.get_pending_txn!()
                             |> Query.AccountTransaction.delete_pending!(AccountTransaction.map_pending(:blockchain_txn_payment_v1, txn))
    rescue
      _error in Ecto.NoResultsError ->
        # nothing to do
        :ok
      _error in Ecto.StaleEntryError ->
        # nothing to do
        :ok
    end
    {:ok, _} = Query.AccountTransaction.create(AccountTransaction.map_cleared(:blockchain_txn_payment_v1, :payee, txn))
    {:ok, _} = Query.AccountTransaction.create(AccountTransaction.map_cleared(:blockchain_txn_payment_v1, :payer, txn))
  end

  defp insert_account_transaction(:blockchain_txn_add_gateway_v1, txn) do
    hash = :blockchain_txn_add_gateway_v1.hash(txn)
    try do
      _pending_account_txn = hash
                             |> Query.AccountTransaction.get_pending_txn!()
                             |> Query.AccountTransaction.delete_pending!(AccountTransaction.map_pending(:blockchain_txn_add_gateway_v1, txn))
    rescue
      _error in Ecto.NoResultsError ->
        # nothing to do
        :ok
      _error in Ecto.StaleEntryError ->
        # nothing to do
        :ok
    end
    {:ok, _} = Query.AccountTransaction.create(AccountTransaction.map_cleared(:blockchain_txn_add_gateway_v1, txn))
  end

  defp insert_account_transaction(:blockchain_txn_gen_gateway_v1, txn) do
    # This can only appear in the genesis block
    {:ok, _} = Query.AccountTransaction.create(AccountTransaction.map_cleared(:blockchain_txn_gen_gateway_v1, txn))
  end

  defp insert_account_transaction(:blockchain_txn_security_coinbase_v1, txn) do
    # This can only appear in the genesis block
    {:ok, _} = Query.AccountTransaction.create(AccountTransaction.map_cleared(:blockchain_txn_security_coinbase_v1, txn))
  end

  defp insert_account_transaction(:blockchain_txn_assert_location_v1, txn) do
    hash = :blockchain_txn_assert_location_v1.hash(txn)
    try do
      _pending_account_txn = hash
                             |> Query.AccountTransaction.get_pending_txn!()
                             |> Query.AccountTransaction.delete_pending!(AccountTransaction.map_pending(:blockchain_txn_assert_location_v1, txn))
    rescue
      _error in Ecto.NoResultsError ->
        # nothing to do
        :ok
      _error in Ecto.StaleEntryError ->
        # nothing to do
        :ok
    end
    {:ok, _} = Query.AccountTransaction.create(AccountTransaction.map_cleared(:blockchain_txn_assert_location_v1, txn))
  end

  defp upsert_hotspot(txn_mod, txn) do
    try do
      hotspot = txn |> txn_mod.gateway() |> Query.Hotspot.get!()
      case Hotspot.map(txn_mod, txn) do
        {:error, _}=error ->
          #XXX: Don't update if googleapi failed?
          error
        map ->
          Query.Hotspot.update!(hotspot, map)
      end
    rescue
      _error in Ecto.NoResultsError ->
        # No hotspot entry exists in the hotspot table
        case Hotspot.map(txn_mod, txn) do
          {:error, _}=error ->
            #XXX: Don't add it if googleapi failed?
            error
          map ->
            Query.Hotspot.create(map)
        end
    end
  end
end
