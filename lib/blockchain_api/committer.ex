defmodule BlockchainAPI.Committer do
  @moduledoc false

  alias BlockchainAPI.{
    Repo,
    Query,
    Schema.Account,
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
    block_txn =
      Repo.transaction(fn() ->

        {:ok, inserted_block} = block |> Block.map() |> Query.Block.create()
        add_transactions(block, ledger)
        add_account_transactions(block)
        commit_account_balances(block, ledger)
        update_account_fee(ledger)
        update_hotspot_score(block, ledger)
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

  defp update_account_fee(ledger) do
    {:ok, fee} = :blockchain_ledger_v1.transaction_fee(ledger)
    Query.Account.update_all_fee(fee)
  end

  defp update_hotspot_score(block, ledger) do
    height = :blockchain_block.height(block)
    :ok = Query.Hotspot.all()
          |> Enum.each(
            fn(hotspot) ->
              {:ok, name} = :erl_angry_purple_tiger.animal_name(:libp2p_crypto.pubkey_to_b58(:libp2p_crypto.bin_to_pubkey(hotspot.address)))
              {:ok, score} = :blockchain_ledger_v1.gateway_score(hotspot.address, ledger)
              {:ok, gwinfo} = :blockchain_ledger_v1.find_gateway_info(hotspot.address, ledger)
              alpha = :blockchain_ledger_gateway_v1.alpha(gwinfo)
              beta = :blockchain_ledger_gateway_v1.beta(gwinfo)
              Logger.debug("Hotspot: #{name}, Score: #{score}, Alpha: #{alpha}, Beta: #{beta}")
              Query.Hotspot.update!(hotspot, %{score: score, score_update_height: height})
            end)
  end

  #==================================================================
  # Add all transactions
  #==================================================================
  defp add_transactions(block, ledger) do
    case :blockchain_block.transactions(block) do
      [] ->
        :ok
      txns ->
        Enum.map(txns, fn txn ->
          case :blockchain_txn.type(txn) do
            :blockchain_txn_coinbase_v1 -> insert_transaction(:blockchain_txn_coinbase_v1, txn, block, ledger)
            :blockchain_txn_payment_v1 -> insert_transaction(:blockchain_txn_payment_v1, txn, block, ledger)
            :blockchain_txn_add_gateway_v1 ->
              insert_transaction(:blockchain_txn_add_gateway_v1, txn, block, ledger)
              upsert_hotspot(:blockchain_txn_add_gateway_v1, txn, ledger)
            :blockchain_txn_gen_gateway_v1 ->
              insert_transaction(:blockchain_txn_gen_gateway_v1, txn, block, ledger)
              upsert_hotspot(:blockchain_txn_gen_gateway_v1, txn, ledger)
            :blockchain_txn_poc_request_v1 -> insert_transaction(:blockchain_txn_poc_request_v1, txn, block, ledger)
            :blockchain_txn_poc_receipts_v1 -> insert_transaction(:blockchain_txn_poc_receipts_v1, txn, block, ledger)
            :blockchain_txn_assert_location_v1 ->
              insert_transaction(:blockchain_txn_assert_location_v1, txn, block, ledger)
              # also upsert hotspot
              upsert_hotspot(:blockchain_txn_assert_location_v1, txn, ledger)
            :blockchain_txn_security_coinbase_v1 -> insert_transaction(:blockchain_txn_security_coinbase_v1, txn, block, ledger)
            :blockchain_txn_consensus_group_v1 -> insert_transaction(:blockchain_txn_consensus_group_v1, txn, block, ledger)
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
  # Insert individual transactions
  #==================================================================
  defp insert_transaction(:blockchain_txn_coinbase_v1, txn, block, _ledger) do
    height = :blockchain_block.height(block)
    {:ok, _transaction_entry} = Query.Transaction.create(height, Transaction.map(:blockchain_txn_coinbase_v1, txn))
    {:ok, _coinbase_entry} = Query.CoinbaseTransaction.create(CoinbaseTransaction.map(txn))

    payee = :blockchain_txn_coinbase_v1.payee(txn)
    amount = :blockchain_txn_coinbase_v1.amount(txn)

    try do
      account = Query.Account.get!(payee)
      {:ok, account_entry} = Account.changeset(account, %{balance: (account.balance + amount)})
                             |> Repo.update()
      AccountChannel.broadcast_change(account_entry)
    rescue
      _error in Ecto.NoResultsError ->
        {:ok, account_entry} = Account.changeset(%Account{}, %{address: payee, balance: amount})
                               |> Repo.insert()
        AccountChannel.broadcast_change(account_entry)
    end
  end

  defp insert_transaction(:blockchain_txn_security_coinbase_v1, txn, block, _ledger) do
    height = :blockchain_block.height(block)
    {:ok, _transaction_entry} = Query.Transaction.create(height, Transaction.map(:blockchain_txn_security_coinbase_v1, txn))
    {:ok, _} = Query.SecurityTransaction.create(SecurityTransaction.map(txn))
  end

  defp insert_transaction(:blockchain_txn_consensus_group_v1, txn, block, _ledger) do
    height = :blockchain_block.height(block)
    {:ok, _transaction_entry} = Query.Transaction.create(height, Transaction.map(:blockchain_txn_consensus_group_v1, txn))
    {:ok, election_entry} = Query.ElectionTransaction.create(ElectionTransaction.map(txn))

    :ok = Enum.each(
      :blockchain_txn_consensus_group_v1.members(txn),
      fn(member) ->
        {:ok, _member_entry} = Query.ConsensusMember.create(ConsensusMember.map(election_entry.id, member))
      end)
  end

  defp insert_transaction(:blockchain_txn_payment_v1, txn, block, _ledger) do
    height = :blockchain_block.height(block)
    {:ok, _transaction_entry} = Query.Transaction.create(height, Transaction.map(:blockchain_txn_payment_v1, txn))
    {:ok, _} = Query.PaymentTransaction.create(PaymentTransaction.map(txn))

    # We need to update accounts here as well
    payee = :blockchain_txn_payment_v1.payee(txn)
    payer = :blockchain_txn_payment_v1.payer(txn)
    amount = :blockchain_txn_payment_v1.amount(txn)
    fee = :blockchain_txn_payment_v1.fee(txn)
    payer_nonce = :blockchain_txn_payment_v1.nonce(txn)

    # The payee can be unknown (a new account for example)
    try do
      payee_account = Query.Account.get!(payee)
      {:ok, payee_account_entry} = Account.changeset(payee_account, %{balance: (payee_account.balance + amount)})
                                   |> Repo.update()
      AccountChannel.broadcast_change(payee_account_entry)
    rescue
      _error in Ecto.NoResultsError ->
        {:ok, payee_account_entry} = Account.changeset(%Account{}, %{address: payee, balance: amount})
                                     |> Repo.insert()
        AccountChannel.broadcast_change(payee_account_entry)
    end

    # A payment transaction cannot originate from an unknown payer
    payer_account = Query.Account.get!(payer)
    {:ok, payer_account_entry} = Account.changeset(payer_account, %{balance: (payer_account.balance - (amount+fee)), nonce: payer_nonce})
                                 |> Repo.update()
    AccountChannel.broadcast_change(payer_account_entry)
  end

  defp insert_transaction(:blockchain_txn_add_gateway_v1, txn, block, _ledger) do
    height = :blockchain_block.height(block)
    {:ok, _transaction_entry} = Query.Transaction.create(height, Transaction.map(:blockchain_txn_add_gateway_v1, txn))
    {:ok, _} = Query.GatewayTransaction.create(GatewayTransaction.map(txn))
  end

  defp insert_transaction(:blockchain_txn_assert_location_v1, txn, block, _ledger) do
    height = :blockchain_block.height(block)
    {:ok, _transaction_entry} = Query.Transaction.create(height, Transaction.map(:blockchain_txn_assert_location_v1, txn))
    {:ok, _} = Query.LocationTransaction.create(LocationTransaction.map(:blockchain_txn_assert_location_v1, txn))
  end

  defp insert_transaction(:blockchain_txn_gen_gateway_v1, txn, block, _ledger) do
    height = :blockchain_block.height(block)
    {:ok, _transaction_entry} = Query.Transaction.create(height, Transaction.map(:blockchain_txn_gen_gateway_v1, txn))

    {:ok, _} = Query.GatewayTransaction.create(GatewayTransaction.map(:genesis, txn))

    case :blockchain_txn_gen_gateway_v1.location(txn) do
      :undefined ->
        :ok
      _ ->
        {:ok, _} = Query.LocationTransaction.create(LocationTransaction.map(:blockchain_txn_gen_gateway_v1, txn))
    end
  end

  defp insert_transaction(:blockchain_txn_poc_request_v1, txn, block, ledger) do
    height = :blockchain_block.height(block)
    {:ok, _transaction_entry} = Query.Transaction.create(height, Transaction.map(:blockchain_txn_poc_request_v1, txn))

    challenger = txn |> :blockchain_txn_poc_request_v1.challenger()

    {:ok, challenger_info} = challenger |> :blockchain_ledger_v1.find_gateway_info(ledger)

    challenger_loc = challenger_info |> :blockchain_ledger_gateway_v1.location()
    challenger_owner = challenger_info |> :blockchain_ledger_gateway_v1.owner_address()

    {:ok, _poc_request_entry} = POCRequestTransaction.map(challenger_loc, challenger_owner, txn)
                                |> Query.POCRequestTransaction.create()

    {:ok, _activity_entry} =
      Query.HotspotActivity.create(%{
        gateway: challenger,
        poc_req_txn_hash: :blockchain_txn.hash(txn),
        poc_req_txn_block_height: height
      })
  end

  defp insert_transaction(:blockchain_txn_poc_receipts_v1, txn, block, ledger) do
    ## TODO: Split this function into smaller helper functions

    height = :blockchain_block.height(block)
    challenger = :blockchain_txn_poc_receipts_v1.challenger(txn)
    onion = :blockchain_txn_poc_receipts_v1.onion_key_hash(txn)
    {:ok, challenger_info} = :blockchain_ledger_v1.find_gateway_info(challenger, ledger)
    challenger_loc = :blockchain_ledger_gateway_v1.location(challenger_info)
    challenger_owner = :blockchain_ledger_gateway_v1.owner_address(challenger_info)
    challengees = for element <- :blockchain_txn_poc_receipts_v1.path(txn), do: :blockchain_poc_path_element_v1.challengee(element)
    {:ok, event_ledger_height} = :blockchain_ledger_v1.current_height(ledger)
    new_chain = :blockchain.ledger(ledger, :blockchain_worker.blockchain())
    chain_ledger = :blockchain.ledger(new_chain)
    {:ok, chain_height} = :blockchain.height(new_chain)
    {:ok, chain_ledger_height} = :blockchain_ledger_v1.current_height(chain_ledger)
    {:ok, lagging_ledger_height} = :blockchain_ledger_v1.current_height(:blockchain_ledger_v1.mode(:delayed, ledger))

    Logger.info("poc_receipt_txn_entry:
      block_height: #{height},
      chain_height: #{chain_height},
      chain_ledger_height: #{chain_ledger_height},
      event_ledger_height: #{event_ledger_height},
      lagging_ledger_height: #{lagging_ledger_height}")

    ## recalculate target
    {:ok, gw_info} = :blockchain_ledger_v1.find_gateway_info(challenger, ledger)
    last_challenge = :blockchain_ledger_gateway_v1.last_poc_challenge(gw_info)
    {:ok, challenge_block} = :blockchain.get_block(last_challenge, new_chain)
    challenge_block_hash = :blockchain_block.hash_block(challenge_block)
    challenge_block_height = :blockchain_block.height(challenge_block)
    Logger.info("challenge block height: #{challenge_block_height}")
    {:ok, old_ledger} = :blockchain.ledger_at(challenge_block_height, new_chain)

    case height == (event_ledger_height + 1) do
      false ->
        raise BlockchainAPI.CommitError, message: "height: #{height}, event_ledger_height: #{event_ledger_height}"
      true ->
        :ok
    end

    case :blockchain_ledger_v1.context_cache(old_ledger) do
      {:undefined, :undefined} ->
        raise BlockchainAPI.CommitError, message: "context and cache missing"
      {:undefined, _} ->
        raise BlockchainAPI.CommitError, message: "context missing"
      {_, :undefined} ->
        raise BlockchainAPI.CommitError, message: "cache missing"
      _ -> :ok
    end

    case :blockchain_ledger_v1.snapshot(old_ledger) do
      {:error, :undefined} ->
        raise BlockchainAPI.CommitError, message: "snapshot missing"
      {:ok, _} ->
        :ok
    end

    secret = :blockchain_txn_poc_receipts_v1.secret(txn)
    entropy = <<secret :: binary, challenge_block_hash :: binary, challenger :: binary>>
    {target, gateways} = :blockchain_poc_path.target(entropy, old_ledger, challenger)
    {:ok, path} = :blockchain_poc_path.build(entropy, target, gateways)
    txn_path0 = :blockchain_txn_poc_receipts_v1.path(txn)
    txn_path = txn_path0 |> Enum.map(fn(element) -> :blockchain_poc_path_element_v1.challengee(element) end)

    ## DB operations
    {:ok, _transaction_entry} = Query.Transaction.create(height, Transaction.map(:blockchain_txn_poc_receipts_v1, txn))
    poc_request = Query.POCRequestTransaction.get_by_onion(onion)
    {:ok, poc_receipt_txn_entry} = POCReceiptsTransaction.map(poc_request.id, challenger_loc, challenger_owner, txn)
                                   |> Query.POCReceiptsTransaction.create()

    case Enum.member?(challengees, target) do
      false ->
        raise BlockchainAPI.CommitError, message: "Target: #{inspect(target)} not in challengees: #{inspect(challengees)}"
      true ->
        case path == txn_path do
          false ->
            raise BlockchainAPI.CommitError, message: "Path: #{inspect(path)} does not match txn_path: #{inspect(txn_path)}"
          true ->
            txn_path0
            |> Enum.map(
              fn(element) when element != :undefined ->
                challengee = element |> :blockchain_poc_path_element_v1.challengee()
                res = challengee |> :blockchain_ledger_v1.find_gateway_info(ledger)

                case res do
                  {:error, _} ->
                    :ok

                  {:ok, challengee_info} ->
                    challengee_loc = :blockchain_ledger_gateway_v1.location(challengee_info)
                    challengee_owner = :blockchain_ledger_gateway_v1.owner_address(challengee_info)
                    is_primary = challengee == target
                    {:ok, path_element_entry} = POCPathElement.map(poc_receipt_txn_entry.hash, challengee_loc, challengee_owner, is_primary, element)
                                                |> Query.POCPathElement.create()

                    case :blockchain_poc_path_element_v1.receipt(element) do
                      :undefined ->
                        :ok
                      receipt ->
                        rx_gateway = receipt |> :blockchain_poc_receipt_v1.gateway()
                        {:ok, rx_info} = rx_gateway |> :blockchain_ledger_v1.find_gateway_info(ledger)
                        rx_loc = :blockchain_ledger_gateway_v1.location(rx_info)
                        rx_owner = :blockchain_ledger_gateway_v1.owner_address(rx_info)
                        {:ok, rx_score} = :blockchain_ledger_v1.gateway_score(rx_gateway, ledger)

                        {:ok, poc_receipt} = POCReceipt.map(path_element_entry.id, rx_loc, rx_owner, receipt)
                                             |> Query.POCReceipt.create()

                        rx_score_delta =
                          case Query.HotspotActivity.last_poc_score(rx_gateway) do
                            nil ->
                              0.0
                            s ->
                              rx_score - s
                          end

                        {:ok, _activity_entry} = Query.HotspotActivity.create(%{
                          gateway: rx_gateway,
                          poc_rx_txn_hash: :blockchain_txn.hash(txn),
                          poc_rx_txn_block_height: height,
                          poc_rx_id: poc_receipt.id,
                          poc_rx_challenge_id: poc_receipt_txn_entry.id,
                          poc_score: rx_score,
                          poc_score_delta: rx_score_delta
                        })

                    end

                    element
                    |> :blockchain_poc_path_element_v1.witnesses()
                    |> Enum.map(
                      fn(witness) when witness != :undefined ->
                        witness_gateway = witness |> :blockchain_poc_witness_v1.gateway()

                        case :blockchain_ledger_v1.find_gateway_info(witness_gateway, ledger) do
                          {:error, _} ->
                            :ok
                          {:ok, wx_info} ->
                            wx_loc = :blockchain_ledger_gateway_v1.location(wx_info)
                            wx_owner = :blockchain_ledger_gateway_v1.owner_address(wx_info)
                            {:ok, wx_score} = :blockchain_ledger_v1.gateway_score(witness_gateway, ledger)

                            {:ok, poc_witness} = POCWitness.map(path_element_entry.id, wx_loc, wx_owner, witness)
                                                 |> Query.POCWitness.create()

                            wx_score_delta =
                              case Query.HotspotActivity.last_poc_score(witness_gateway) do
                                nil ->
                                  0.0
                                s ->
                                  wx_score - s
                              end

                            {:ok, _activity_entry} = Query.HotspotActivity.create(%{
                              gateway: witness_gateway,
                              poc_rx_txn_hash: :blockchain_txn.hash(txn),
                              poc_rx_txn_block_height: height,
                              poc_witness_id: poc_witness.id,
                              poc_witness_challenge_id: poc_receipt_txn_entry.id,
                              poc_score: wx_score,
                              poc_score_delta: wx_score_delta
                            })
                        end
                      end)
                end
              end)
        end
    end
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

  defp upsert_hotspot(txn_mod, txn, ledger) do
    try do
      hotspot = txn |> txn_mod.gateway() |> Query.Hotspot.get!()
      case Hotspot.map(txn_mod, txn, ledger) do
        {:error, _}=error ->
          #XXX: Don't update if googleapi failed?
          error
        map ->
          Query.Hotspot.update!(hotspot, map)
      end
    rescue
      _error in Ecto.NoResultsError ->
        # No hotspot entry exists in the hotspot table
        case Hotspot.map(txn_mod, txn, ledger) do
          {:error, _}=error ->
            #XXX: Don't add it if googleapi failed?
            error
          map ->
            Query.Hotspot.create(map)
        end
    end
  end
end
