defmodule BlockchainAPI.Committer do
  @moduledoc false

  alias BlockchainAPI.{
    Query,
    Repo,
    Schema.Account,
    Schema.AccountBalance,
    Schema.AccountTransaction,
    Schema.Block,
    Schema.CoinbaseTransaction,
    Schema.ConsensusMember,
    Schema.DataCreditTransaction,
    Schema.ElectionTransaction,
    Schema.GatewayTransaction,
    Schema.Hotspot,
    Schema.LocationTransaction,
    Schema.PaymentTransaction,
    Schema.POCPathElement,
    Schema.POCReceipt,
    Schema.POCReceiptsTransaction,
    Schema.POCRequestTransaction,
    Schema.POCWitness,
    Schema.RewardsTransaction,
    Schema.RewardTxn,
    Schema.SecurityTransaction,
    Schema.OUITransaction,
    Schema.SecurityExchangeTransaction,
    Schema.Transaction,
    Util,
    Notifier
  }

  alias BlockchainAPIWeb.BlockChannel
  alias BlockchainAPI.Cache.CacheService

  require Logger

  def commit(block, ledger, height, sync_flag, env) do
    case commit_block(block, ledger, height) do
      {:ok, term} ->
        # block has been committed, refresh the cache.
        if !sync_flag, do: CacheService.purge_key("block")
        notify(env, block, ledger, sync_flag)
        Logger.info("Success! Commit block: #{height}")
        {:ok, term}

      {:error, reason} ->
        Logger.error("Failure! Commit block: #{height}. Reason: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp commit_block(block, ledger, height) do
    Repo.transaction(fn ->
      case Query.Block.create(Block.map(block)) do
        {:error, _reason} = e ->
          e

        {:ok, inserted_block} ->
          add_transactions(block, ledger, height)
          add_account_transactions(block)
          commit_account_balances(block, ledger)
          insert_or_update_all_account(ledger)
          update_hotspot_score(ledger, height)
          # NOTE: move this elsewhere...
          BlockChannel.broadcast_change(inserted_block)
      end
    end)
  end

  defp notify(:prod, block, ledger, false), do: Notifier.notify(block, ledger)
  defp notify(_env, _block, _ledger, _sync_flag), do: :ok

  defp commit_account_balances(block, ledger) do
    account_bal_txn =
      Repo.transaction(fn ->
        add_account_balances(block, ledger)
      end)

    case account_bal_txn do
      {:ok, term} ->
        {:ok, term}

      {:error, reason} ->
        Logger.error(
          "Failed to commit account_balances at height: #{:blockchain_block.height(block)} to db!"
        )

        {:error, reason}
    end
  end

  defp insert_or_update_all_account(ledger) do
    {:ok, fee} = :blockchain_ledger_v1.transaction_fee(ledger)

    hlm_maps =
      ledger
      |> :blockchain_ledger_v1.entries()
      |> Stream.map(fn {address, entry} ->
        %{
          nonce: :blockchain_ledger_entry_v1.nonce(entry),
          balance: :blockchain_ledger_entry_v1.balance(entry),
          address: address,
          fee: fee
        }
      end)

    security_maps =
      ledger
      |> :blockchain_ledger_v1.securities()
      |> Stream.map(fn {address, entry} ->
        %{
          security_nonce: :blockchain_ledger_security_entry_v1.nonce(entry),
          security_balance: :blockchain_ledger_security_entry_v1.balance(entry),
          address: address
        }
      end)

    data_credit_maps =
      ledger
      |> :blockchain_ledger_v1.dc_entries()
      |> Stream.map(fn {address, entry} ->
        %{
          data_credit_balance: :blockchain_ledger_data_credits_entry_v1.balance(entry),
          address: address
        }
      end)

    account_maps =
      hlm_maps
      |> Stream.concat(security_maps)
      |> Stream.concat(data_credit_maps)
      |> Enum.reduce(%{}, fn entry, acc ->
        case Map.get(acc, entry[:address]) do
          nil ->
            Map.put(acc, entry[:address], entry)

          map ->
            updated_entry = Map.merge(map, entry)
            Map.put(acc, entry[:address], updated_entry)
        end
      end)

    Repo.transaction(fn ->
      Enum.each(
        account_maps,
        fn {_address, map} ->
          params = %{
            balance: Map.get(map, :balance, 0),
            nonce: Map.get(map, :nonce, 0),
            fee: Map.get(map, :fee, 0),
            security_nonce: Map.get(map, :security_nonce, 0),
            security_balance: Map.get(map, :security_balance, 0),
            data_credit_balance: Map.get(map, :data_credit_balance, 0)
          }

          case Query.Account.get(map.address) do
            nil ->
              Account.changeset(%Account{}, Map.put(params, :address, map.address))

            account ->
              Account.changeset(account, params)
          end
          |> Repo.insert_or_update!()
        end
      )
    end)
  end

  defp update_hotspot_score(ledger, height) do
    :ok =
      Query.Hotspot.all()
      |> Enum.each(fn hotspot ->
        case :blockchain_ledger_v1.gateway_score(hotspot.address, ledger) do
          {:error, _} ->
            :ok

          {:ok, score} ->
            Query.Hotspot.update!(hotspot, %{score: score, score_update_height: height})
        end
      end)
  end

  # ==================================================================
  # Add all transactions
  # ==================================================================
  defp add_transactions(block, ledger, height) do
    case :blockchain_block.transactions(block) do
      [] ->
        :ok

      txns ->
        Enum.map(txns, fn txn ->
          case :blockchain_txn.type(txn) do
            :blockchain_txn_coinbase_v1 ->
              insert_transaction(:blockchain_txn_coinbase_v1, txn, height)

            :blockchain_txn_payment_v1 ->
              insert_transaction(:blockchain_txn_payment_v1, txn, height)

            :blockchain_txn_add_gateway_v1 ->
              insert_transaction(:blockchain_txn_add_gateway_v1, txn, height)
              upsert_hotspot(:blockchain_txn_add_gateway_v1, txn, ledger)

            :blockchain_txn_gen_gateway_v1 ->
              insert_transaction(:blockchain_txn_gen_gateway_v1, txn, height)
              upsert_hotspot(:blockchain_txn_gen_gateway_v1, txn, ledger)

            :blockchain_txn_poc_request_v1 ->
              insert_transaction(:blockchain_txn_poc_request_v1, txn, block, ledger, height)

            :blockchain_txn_poc_receipts_v1 ->
              insert_transaction(:blockchain_txn_poc_receipts_v1, txn, block, ledger, height)

            :blockchain_txn_assert_location_v1 ->
              insert_transaction(:blockchain_txn_assert_location_v1, txn, height)
              # also upsert hotspot
              upsert_hotspot(:blockchain_txn_assert_location_v1, txn, ledger)

            :blockchain_txn_security_coinbase_v1 ->
              insert_transaction(:blockchain_txn_security_coinbase_v1, txn, height)

            :blockchain_txn_security_exchange_v1 ->
              insert_transaction(:blockchain_txn_security_exchange_v1, txn, height)

            :blockchain_txn_dc_coinbase_v1 ->
              insert_transaction(:blockchain_txn_dc_coinbase_v1, txn, height)

            :blockchain_txn_consensus_group_v1 ->
              insert_transaction(
                :blockchain_txn_consensus_group_v1,
                txn,
                height,
                :blockchain_block.time(block)
              )

            :blockchain_txn_rewards_v1 ->
              insert_transaction(
                :blockchain_txn_rewards_v1,
                txn,
                height,
                :blockchain_block.time(block)
              )

            :blockchain_txn_oui_v1 ->
              insert_transaction(:blockchain_txn_oui_v1, txn, height)

            _ ->
              :ok
          end
        end)
    end
  end

  # ==================================================================
  # Add all account transactions
  # ==================================================================
  defp add_account_transactions(block) do
    case :blockchain_block.transactions(block) do
      [] ->
        :ok

      txns ->
        Enum.map(txns, fn txn ->
          case :blockchain_txn.type(txn) do
            :blockchain_txn_coinbase_v1 ->
              insert_account_transaction(:blockchain_txn_coinbase_v1, txn)

            :blockchain_txn_payment_v1 ->
              insert_account_transaction(:blockchain_txn_payment_v1, txn)

            :blockchain_txn_add_gateway_v1 ->
              insert_account_transaction(:blockchain_txn_add_gateway_v1, txn)

            :blockchain_txn_assert_location_v1 ->
              insert_account_transaction(:blockchain_txn_assert_location_v1, txn)

            :blockchain_txn_gen_gateway_v1 ->
              insert_account_transaction(:blockchain_txn_gen_gateway_v1, txn)

            :blockchain_txn_security_coinbase_v1 ->
              insert_account_transaction(:blockchain_txn_security_coinbase_v1, txn)

            :blockchain_txn_dc_coinbase_v1 ->
              insert_account_transaction(:blockchain_txn_dc_coinbase_v1, txn)

            :blockchain_txn_rewards_v1 ->
              insert_account_transaction(:blockchain_txn_rewards_v1, txn)

            _ ->
              :ok
          end
        end)
    end
  end

  # ==================================================================
  # Add all account balances (if there is a change)
  # ==================================================================
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
                AccountBalance.map(
                  address,
                  ledger_entry_balance,
                  block,
                  ledger_entry_balance - account_entry_balance
                )
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

  # ==================================================================
  # Insert individual transactions
  # ==================================================================
  defp insert_transaction(:blockchain_txn_coinbase_v1, txn, height) do
    {:ok, _transaction_entry} =
      Query.Transaction.create(height, Transaction.map(:blockchain_txn_coinbase_v1, txn))

    {:ok, _coinbase_entry} = Query.CoinbaseTransaction.create(CoinbaseTransaction.map(txn))
  end

  defp insert_transaction(:blockchain_txn_security_coinbase_v1, txn, height) do
    {:ok, _transaction_entry} =
      Query.Transaction.create(height, Transaction.map(:blockchain_txn_security_coinbase_v1, txn))

    {:ok, _} = Query.SecurityTransaction.create(SecurityTransaction.map(txn))
  end

  defp insert_transaction(:blockchain_txn_security_exchange_v1, txn, height) do
    {:ok, _transaction_entry} =
      Query.Transaction.create(height, Transaction.map(:blockchain_txn_security_exchange_v1, txn))

    {:ok, _} = Query.SecurityExchangeTransaction.create(SecurityExchangeTransaction.map(txn))
  end

  defp insert_transaction(:blockchain_txn_dc_coinbase_v1, txn, height) do
    {:ok, _transaction_entry} =
      Query.Transaction.create(height, Transaction.map(:blockchain_txn_dc_coinbase_v1, txn))

    {:ok, _} = Query.DataCreditTransaction.create(DataCreditTransaction.map(txn))
  end

  defp insert_transaction(:blockchain_txn_payment_v1, txn, height) do
    {:ok, _transaction_entry} =
      Query.Transaction.create(height, Transaction.map(:blockchain_txn_payment_v1, txn))

    {:ok, _} = Query.PaymentTransaction.create(PaymentTransaction.map(txn))
  end

  defp insert_transaction(:blockchain_txn_add_gateway_v1, txn, height) do
    {:ok, _transaction_entry} =
      Query.Transaction.create(height, Transaction.map(:blockchain_txn_add_gateway_v1, txn))

    {:ok, _} = Query.GatewayTransaction.create(GatewayTransaction.map(txn))
  end

  defp insert_transaction(:blockchain_txn_assert_location_v1, txn, height) do
    {:ok, _transaction_entry} =
      Query.Transaction.create(height, Transaction.map(:blockchain_txn_assert_location_v1, txn))

    {:ok, _} =
      Query.LocationTransaction.create(
        LocationTransaction.map(:blockchain_txn_assert_location_v1, txn)
      )
  end

  defp insert_transaction(:blockchain_txn_gen_gateway_v1, txn, height) do
    {:ok, _transaction_entry} =
      Query.Transaction.create(height, Transaction.map(:blockchain_txn_gen_gateway_v1, txn))

    {:ok, _} = Query.GatewayTransaction.create(GatewayTransaction.map(:genesis, txn))

    case :blockchain_txn_gen_gateway_v1.location(txn) do
      :undefined ->
        :ok

      _ ->
        {:ok, _} =
          Query.LocationTransaction.create(
            LocationTransaction.map(:blockchain_txn_gen_gateway_v1, txn)
          )
    end
  end

  defp insert_transaction(:blockchain_txn_oui_v1, txn, height) do
    {:ok, _transaction_entry} =
      Query.Transaction.create(height, Transaction.map(:blockchain_txn_oui_v1, txn))

    {:ok, _} = Query.OUITransaction.create(OUITransaction.map(txn))
  end

  defp insert_transaction(:blockchain_txn_consensus_group_v1, txn, height, time) do
    {:ok, _transaction_entry} =
      Query.Transaction.create(height, Transaction.map(:blockchain_txn_consensus_group_v1, txn))

    {:ok, election_entry} = Query.ElectionTransaction.create(ElectionTransaction.map(txn))

    members = :blockchain_txn_consensus_group_v1.members(txn)

    :ok =
      Enum.each(
        members,
        fn member ->
          {:ok, _member_entry} =
            Query.ConsensusMember.create(ConsensusMember.map(election_entry.id, member))
        end
      )

    :ok =
      Enum.each(
        members,
        fn member0 ->
          {:ok, _activity_entry} =
            Query.HotspotActivity.create(%{
              gateway: member0,
              in_consensus: true,
              election_id: election_entry.id,
              election_block_height: :blockchain_txn_consensus_group_v1.height(txn),
              election_txn_block_height: height,
              election_txn_block_time: time
            })
        end
      )
  end

  defp insert_transaction(:blockchain_txn_rewards_v1, txn, height, time) do
    {:ok, _transaction_entry} =
      Query.Transaction.create(height, Transaction.map(:blockchain_txn_rewards_v1, txn))

    {:ok, rewards_txn} = Query.RewardsTransaction.create(RewardsTransaction.map(txn))

    rewards = :blockchain_txn_rewards_v1.rewards(txn)

    :ok =
      rewards
      |> Enum.each(fn reward_txn ->
        RewardTxn.map(rewards_txn.hash, reward_txn)
        |> Query.RewardTxn.create()
      end)

    :ok =
      rewards
      |> Enum.each(fn reward ->
        case :blockchain_txn_reward_v1.type(reward) do
          :securities ->
            :ok

          type ->
            {:ok, _activity_entry} =
              Query.HotspotActivity.create(%{
                gateway: :blockchain_txn_reward_v1.gateway(reward),
                reward_type: to_string(type),
                reward_amount: :blockchain_txn_reward_v1.amount(reward),
                reward_block_height: height,
                reward_block_time: time
              })
        end
      end)
  end

  defp insert_transaction(:blockchain_txn_poc_request_v1, txn, block, ledger, height) do
    time = :blockchain_block.time(block)

    {:ok, _transaction_entry} =
      Query.Transaction.create(height, Transaction.map(:blockchain_txn_poc_request_v1, txn))

    challenger = txn |> :blockchain_txn_poc_request_v1.challenger()

    {:ok, challenger_info} = challenger |> :blockchain_ledger_v1.find_gateway_info(ledger)

    challenger_loc = challenger_info |> :blockchain_ledger_gateway_v2.location()
    challenger_owner = challenger_info |> :blockchain_ledger_gateway_v2.owner_address()

    {:ok, _poc_request_entry} =
      POCRequestTransaction.map(challenger_loc, challenger_owner, txn)
      |> Query.POCRequestTransaction.create()

    {:ok, _activity_entry} =
      Query.HotspotActivity.create(%{
        gateway: challenger,
        poc_req_txn_hash: :blockchain_txn.hash(txn),
        poc_req_txn_block_height: height,
        poc_req_txn_block_time: time
      })
  end

  defp insert_transaction(:blockchain_txn_poc_receipts_v1, txn, block, ledger, height) do
    challenger = :blockchain_txn_poc_receipts_v1.challenger(txn)
    onion = :blockchain_txn_poc_receipts_v1.onion_key_hash(txn)
    {:ok, challenger_info} = :blockchain_ledger_v1.find_gateway_info(challenger, ledger)
    challenger_loc = :blockchain_ledger_gateway_v2.location(challenger_info)
    challenger_owner = :blockchain_ledger_gateway_v2.owner_address(challenger_info)

    # Create transaction entry
    {:ok, _transaction_entry} =
      Query.Transaction.create(height, Transaction.map(:blockchain_txn_poc_receipts_v1, txn))

    # Create POC Receipts transaction entry
    poc_request = Query.POCRequestTransaction.get_by_onion(onion)

    {:ok, poc_receipt_txn_entry} =
      POCReceiptsTransaction.map(poc_request.id, challenger_loc, challenger_owner, txn)
      |> Query.POCReceiptsTransaction.create()

    # Populate receipt and witness tables from the poc path _without_ any vaidation. It's done in core.
    insert_receipt_and_witnesses(txn, block, ledger, height, poc_receipt_txn_entry)
  end

  # ==================================================================
  # Insert account transactions
  # ==================================================================
  defp insert_account_transaction(:blockchain_txn_coinbase_v1, txn) do
    hash = :blockchain_txn_coinbase_v1.hash(txn)

    try do
      _pending_account_txn =
        hash
        |> Query.AccountTransaction.get_pending_txn!()
        |> Query.AccountTransaction.delete_pending!(
          AccountTransaction.map_pending(:blockchain_txn_coinbase_v1, txn)
        )
    rescue
      _error in Ecto.NoResultsError ->
        # nothing to do
        :ok

      _error in Ecto.StaleEntryError ->
        # nothing to do
        :ok
    end

    {:ok, _} =
      Query.AccountTransaction.create(
        AccountTransaction.map_cleared(:blockchain_txn_coinbase_v1, txn)
      )
  end

  defp insert_account_transaction(:blockchain_txn_payment_v1, txn) do
    hash = :blockchain_txn_payment_v1.hash(txn)

    try do
      _pending_account_txn =
        hash
        |> Query.AccountTransaction.get_pending_txn!()
        |> Query.AccountTransaction.delete_pending!(
          AccountTransaction.map_pending(:blockchain_txn_payment_v1, txn)
        )
    rescue
      _error in Ecto.NoResultsError ->
        # nothing to do
        :ok

      _error in Ecto.StaleEntryError ->
        # nothing to do
        :ok
    end

    {:ok, _} =
      Query.AccountTransaction.create(
        AccountTransaction.map_cleared(:blockchain_txn_payment_v1, :payee, txn)
      )

    {:ok, _} =
      Query.AccountTransaction.create(
        AccountTransaction.map_cleared(:blockchain_txn_payment_v1, :payer, txn)
      )
  end

  defp insert_account_transaction(:blockchain_txn_add_gateway_v1, txn) do
    hash = :blockchain_txn_add_gateway_v1.hash(txn)

    try do
      _pending_account_txn =
        hash
        |> Query.AccountTransaction.get_pending_txn!()
        |> Query.AccountTransaction.delete_pending!(
          AccountTransaction.map_pending(:blockchain_txn_add_gateway_v1, txn)
        )
    rescue
      _error in Ecto.NoResultsError ->
        # nothing to do
        :ok

      _error in Ecto.StaleEntryError ->
        # nothing to do
        :ok
    end

    {:ok, _} =
      Query.AccountTransaction.create(
        AccountTransaction.map_cleared(:blockchain_txn_add_gateway_v1, txn)
      )
  end

  defp insert_account_transaction(:blockchain_txn_gen_gateway_v1, txn) do
    # This can only appear in the genesis block
    {:ok, _} =
      Query.AccountTransaction.create(
        AccountTransaction.map_cleared(:blockchain_txn_gen_gateway_v1, txn)
      )
  end

  defp insert_account_transaction(:blockchain_txn_security_coinbase_v1, txn) do
    # This can only appear in the genesis block
    {:ok, _} =
      Query.AccountTransaction.create(
        AccountTransaction.map_cleared(:blockchain_txn_security_coinbase_v1, txn)
      )
  end

  defp insert_account_transaction(:blockchain_txn_dc_coinbase_v1, txn) do
    # This can only appear in the genesis block
    {:ok, _} =
      Query.AccountTransaction.create(
        AccountTransaction.map_cleared(:blockchain_txn_dc_coinbase_v1, txn)
      )
  end

  defp insert_account_transaction(:blockchain_txn_assert_location_v1, txn) do
    hash = :blockchain_txn_assert_location_v1.hash(txn)

    try do
      _pending_account_txn =
        hash
        |> Query.AccountTransaction.get_pending_txn!()
        |> Query.AccountTransaction.delete_pending!(
          AccountTransaction.map_pending(:blockchain_txn_assert_location_v1, txn)
        )
    rescue
      _error in Ecto.NoResultsError ->
        # nothing to do
        :ok

      _error in Ecto.StaleEntryError ->
        # nothing to do
        :ok
    end

    {:ok, _} =
      Query.AccountTransaction.create(
        AccountTransaction.map_cleared(:blockchain_txn_assert_location_v1, txn)
      )
  end

  defp insert_account_transaction(:blockchain_txn_rewards_v1, txn) do
    changesets =
      txn
      |> :blockchain_txn_rewards_v1.rewards()
      |> Enum.reduce(
        [],
        fn reward_txn, acc ->
          changeset =
            AccountTransaction.changeset(
              %AccountTransaction{},
              AccountTransaction.map_cleared(
                :blockchain_txn_reward_v1,
                :blockchain_txn_rewards_v1.hash(txn),
                reward_txn
              )
            )

          [changeset | acc]
        end
      )

    Repo.transaction(fn -> Enum.each(changesets, &Repo.insert!(&1, [])) end)
  end

  defp upsert_hotspot(txn_mod, txn, ledger) do
    try do
      hotspot = txn |> txn_mod.gateway() |> Query.Hotspot.get!()

      case Hotspot.map(txn_mod, txn, ledger) do
        {:error, _} = error ->
          # XXX: Don't update if googleapi failed?
          error

        map ->
          Query.Hotspot.update!(hotspot, map)
      end
    rescue
      _error in Ecto.NoResultsError ->
        # No hotspot entry exists in the hotspot table
        case Hotspot.map(txn_mod, txn, ledger) do
          {:error, _} = error ->
            # XXX: Don't add it if googleapi failed?
            error

          map ->
            Query.Hotspot.create(map)
        end
    end
  end

  # POC Related private db helper functions. Maybe move to a separate module?
  defp insert_receipt_and_witnesses(txn, block, ledger, height, poc_receipt_txn_entry) do
    deltas = :blockchain_txn_poc_receipts_v1.deltas(txn)
    time = :blockchain_block.time(block)

    txn
    |> :blockchain_txn_poc_receipts_v1.path()
    |> Enum.with_index()
    |> Enum.map(fn {element, index} when element != :undefined ->
      challengee = element |> :blockchain_poc_path_element_v1.challengee()
      res = challengee |> :blockchain_ledger_v1.find_gateway_info(ledger)

      case res do
        {:error, _} ->
          :ok

        {:ok, challengee_info} ->
          challengee_loc = :blockchain_ledger_gateway_v2.location(challengee_info)
          challengee_owner = :blockchain_ledger_gateway_v2.owner_address(challengee_info)

          delta = Enum.at(deltas, index)

          {:ok, path_element_entry} =
            POCPathElement.map(
              poc_receipt_txn_entry.hash,
              challengee,
              challengee_loc,
              challengee_owner,
              poc_result(delta)
            )
            |> Query.POCPathElement.create()

          _ =
            add_receipt(
              txn,
              height,
              time,
              ledger,
              element,
              path_element_entry,
              poc_receipt_txn_entry
            )

          _ =
            add_witnesses(
              txn,
              height,
              time,
              ledger,
              element,
              path_element_entry,
              poc_receipt_txn_entry
            )
      end
    end)
  end

  defp add_witnesses(
         txn,
         height,
         time,
         ledger,
         element,
         path_element_entry,
         poc_receipt_txn_entry
       ) do
    element
    |> :blockchain_poc_path_element_v1.witnesses()
    |> Enum.map(fn witness when witness != :undefined ->
      witness_gateway = witness |> :blockchain_poc_witness_v1.gateway()

      case :blockchain_ledger_v1.find_gateway_info(witness_gateway, ledger) do
        {:error, _} ->
          :ok

        {:ok, wx_info} ->
          wx_loc = :blockchain_ledger_gateway_v2.location(wx_info)
          wx_owner = :blockchain_ledger_gateway_v2.owner_address(wx_info)
          {:ok, wx_score} = :blockchain_ledger_v1.gateway_score(witness_gateway, ledger)

          distance =
            Util.h3_distance_in_meters(
              wx_loc,
              path_element_entry.challengee_loc |> String.to_charlist() |> :h3.from_string()
            )

          {:ok, poc_witness} =
            POCWitness.map(path_element_entry.id, wx_loc, distance, wx_owner, witness)
            |> Query.POCWitness.create()

          wx_score_delta =
            case Query.HotspotActivity.last_poc_score(witness_gateway) do
              nil ->
                0.0

              s ->
                wx_score - s
            end

          {:ok, _activity_entry} =
            Query.HotspotActivity.create(%{
              gateway: witness_gateway,
              poc_rx_txn_hash: :blockchain_txn.hash(txn),
              poc_rx_txn_block_height: height,
              poc_rx_txn_block_time: time,
              poc_witness_id: poc_witness.id,
              poc_witness_challenge_id: poc_receipt_txn_entry.id,
              poc_score: wx_score,
              poc_score_delta: wx_score_delta
            })
      end
    end)
  end

  defp add_receipt(txn, height, time, ledger, element, path_element_entry, poc_receipt_txn_entry) do
    case :blockchain_poc_path_element_v1.receipt(element) do
      :undefined ->
        :ok

      receipt ->
        rx_gateway = receipt |> :blockchain_poc_receipt_v1.gateway()
        {:ok, rx_info} = rx_gateway |> :blockchain_ledger_v1.find_gateway_info(ledger)
        rx_loc = :blockchain_ledger_gateway_v2.location(rx_info)
        rx_owner = :blockchain_ledger_gateway_v2.owner_address(rx_info)
        {:ok, rx_score} = :blockchain_ledger_v1.gateway_score(rx_gateway, ledger)

        {:ok, poc_receipt} =
          POCReceipt.map(path_element_entry.id, rx_loc, rx_owner, receipt)
          |> Query.POCReceipt.create()

        rx_score_delta =
          case Query.HotspotActivity.last_poc_score(rx_gateway) do
            nil ->
              0.0

            s ->
              rx_score - s
          end

        {:ok, _activity_entry} =
          Query.HotspotActivity.create(%{
            gateway: rx_gateway,
            poc_rx_txn_hash: :blockchain_txn.hash(txn),
            poc_rx_txn_block_height: height,
            poc_rx_txn_block_time: time,
            poc_rx_id: poc_receipt.id,
            poc_rx_challenge_id: poc_receipt_txn_entry.id,
            poc_score: rx_score,
            poc_score_delta: rx_score_delta
          })

        rapid_decline(rx_gateway, time)
    end
  end

  defp rapid_decline(challengee, time) do
    challenge_results = Query.POCPathElement.get_last_ten(challengee)

    case length(challenge_results) == 10 do
      false ->
        :ok

      true ->
        case Enum.any?(challenge_results, fn res -> res == "success" end) do
          true ->
            :ok

          false ->
            case Enum.count(challenge_results, fn res -> res == "failure" end) do
              c when c >= 4 ->
                Query.HotspotActivity.create(%{
                  gateway: challengee,
                  rapid_decline: true,
                  poc_rx_txn_block_time: time
                })

              _ ->
                :ok
            end
        end
    end
  end

  defp poc_result(nil), do: "untested"
  defp poc_result({_, {0, 0}}), do: "untested"

  defp poc_result({_, {a, b}}) do
    case a > b do
      true -> "success"
      false -> "failure"
    end
  end
end
