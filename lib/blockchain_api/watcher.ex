defmodule BlockchainAPI.Watcher do
  use GenServer
  alias BlockchainAPI.Explorer

  @me __MODULE__
  require Logger


  #==================================================================
  # API
  #==================================================================
  def start_link(args) do
    GenServer.start_link(@me, args, name: @me)
  end

  def chain() do
    GenServer.call(@me, :chain, :infinity)
  end

  def height() do
    GenServer.call(@me, :height, :infinity)
  end

  def last_block_time() do
    GenServer.call(@me, :last_block_time, :infinity)
  end

  #==================================================================
  # GenServer Callbacks
  #==================================================================
  @impl true
  def init(args) do
    :ok = :blockchain_event.add_handler(self())

    state =
      case Keyword.get(args, :env) do
        :test ->
          %{chain: nil}
        :dev ->
          %{chain: nil}
        :prod ->
          genesis_file = Path.join(:code.priv_dir(:blockchain_api), "genesis")
          case File.read(genesis_file) do
            {:ok, genesis_block} ->
              :ok = genesis_block
                    |> :blockchain_block.deserialize()
                    |> :blockchain_worker.integrate_genesis_block()
              chain = :blockchain_worker.blockchain()
              %{chain: chain}
            {:error, _reason} ->
              %{chain: nil}
          end
      end

    {:ok, state}
  end

  @impl true
  def handle_call(:chain, _from, state = %{chain: chain}) do
    {:reply, chain, state}
  end

  @impl true
  def handle_call(:height, _from, state = %{chain: nil}) do
    {:reply, 0, state}
  end
  def handle_call(:height, _from, state = %{chain: chain}) do
    {:ok, height} = :blockchain.height(chain)
    {:reply, height, state}
  end

  @impl true
  def handle_call(:last_block_time, _from, state = %{chain: nil}) do
    {:reply, 0, state}
  end
  def handle_call(:last_block_time, _from, state = %{chain: chain}) do
    {:ok, head_block} = :blockchain.head_block(chain)
    time = :blockchain_block.meta(head_block).block_time
    {:reply, time, state}
  end

  @impl true
  def handle_info({:blockchain_event, {:integrate_genesis_block, {:ok, genesis_hash}}}, _state) do
    Logger.info("Got integrate_genesis_block event")
    chain = :blockchain_worker.blockchain()
    {:ok, block} = :blockchain.get_block(genesis_hash, chain)
    add_block(block, chain)
    {:noreply, %{chain: chain}}
  end

  @impl true
  def handle_info({:blockchain_event, {:add_block, hash, _flag}}, state = %{chain: chain}) when chain != nil do
    Logger.info("Got add_block event")
    {:ok, block} = :blockchain.get_block(hash, chain)
    add_block(block, chain)
    {:noreply, state}
  end

  @impl true
  def handle_info(_, state) do
    {:noreply, state}
  end

  #==================================================================
  # Private Functions
  #==================================================================
  defp add_block(block_to_add, chain) do
    height = :blockchain_block.height(block_to_add)
    try do
      Explorer.get_block!(height)
    rescue
      _error in Ecto.NoResultsError ->
        case Explorer.get_latest() do
          [nil] ->
            # nothing in the db yet
            {:ok, _block} = Explorer.create_block(block_map(block_to_add))
            add_accounts(block_to_add, chain)
            add_transactions(block_to_add)
            add_account_transactions(block_to_add)
          [last_known_height] ->
            case height > last_known_height do
              true ->
                missing_blocks =
                  Range.new(last_known_height + 1, height)
                  |> Enum.map(fn h ->
                    {:ok, b} = :blockchain.get_block(h, chain)
                    b
                  end)

                Enum.map(missing_blocks,
                  fn b ->
                    Explorer.create_block(block_map(b))
                    add_accounts(b, chain)
                    add_transactions(b)
                    add_account_transactions(b)
                  end)
                # Enum.map(missing_blocks, fn b -> add_transactions(b) end)
              false ->
                :ok
            end
        end
    end
  end

  defp add_accounts(block, chain) do

    # A block may contain multiple transactions of different types
    # There could also be multiple transactions made from the same account address
    # Since this is just add_accounts, and address is a primary key, I think it's probably
    # fine to add it directly, BUT the balance needs to be updated at the end for the account

    ledger = :blockchain.ledger(chain)

    case :blockchain_block.transactions(block) do
      [] ->
        :ok
      txns ->
        Enum.map(txns,
          fn txn ->
            case :blockchain_transactions.type(txn) do
              :blockchain_txn_coinbase_v1 ->
                addr = :blockchain_txn_coinbase_v1.payee(txn)
                addr_str = to_string(:libp2p_crypto.address_to_b58(addr))
                {:ok, entry} = :blockchain_ledger_v1.find_entry(addr, ledger)
                try do
                  account = Explorer.get_account!(addr_str)
                  account_map = %{balance: :blockchain_ledger_entry_v1.balance(entry)}
                  Explorer.update_account(account, account_map)
                rescue
                  _error in Ecto.NoResultsError ->
                    account_map = %{address: addr_str, balance: :blockchain_ledger_entry_v1.balance(entry)}
                    Explorer.create_account(account_map)
                end
              :blockchain_txn_payment_v1 ->
                payee = :blockchain_txn_payment_v1.payee(txn)
                payer = :blockchain_txn_payment_v1.payer(txn)
                payee_str = to_string(:libp2p_crypto.address_to_b58(payee))
                payer_str = to_string(:libp2p_crypto.address_to_b58(payer))
                {:ok, payee_entry} = :blockchain_ledger_v1.find_entry(payee, ledger)
                {:ok, payer_entry} = :blockchain_ledger_v1.find_entry(payer, ledger)
                try do
                  payer_account = Explorer.get_account!(payer_str)
                  payer_map = %{balance: :blockchain_ledger_entry_v1.balance(payer_entry)}
                  payee_account = Explorer.get_account!(payee_str)
                  payee_map = %{balance: :blockchain_ledger_entry_v1.balance(payee_entry)}
                  Explorer.update_account(payer_account, payer_map)
                  Explorer.update_account(payee_account, payee_map)
                rescue
                  _error in Ecto.NoResultsError ->
                    payee_map = %{address: payee_str, balance: :blockchain_ledger_entry_v1.balance(payee_entry)}
                    payer_map = %{address: payer_str, balance: :blockchain_ledger_entry_v1.balance(payer_entry)}
                    Explorer.create_account(payer_map)
                    Explorer.create_account(payee_map)
                end
              _ ->
                :ok
            end
          end)
    end

  end

  defp add_account_transactions(block) do
  end

  defp add_transactions(block) do
    height = :blockchain_block.height(block)
    case :blockchain_block.transactions(block) do
      [] ->
        :ok
      txns ->
        Enum.map(txns, fn txn ->
          case :blockchain_transactions.type(txn) do
            :blockchain_txn_coinbase_v1 ->
              txn_map =
                %{type: "coinbase",
                  hash: Base.encode16(:blockchain_txn_coinbase_v1.hash(txn), case: :lower)}
              {:ok, transaction_entry} = Explorer.create_transaction(height, txn_map)
              BlockchainAPI.Repo.preload transaction_entry, [:coinbase_transactions]
              Explorer.create_coinbase(transaction_entry.hash, coinbase_map(txn))
            :blockchain_txn_payment_v1 ->
              txn_map =
                %{type: "payment",
                  hash: Base.encode16(:blockchain_txn_payment_v1.hash(txn), case: :lower)}
              {:ok, transaction_entry} = Explorer.create_transaction(height, txn_map)
              BlockchainAPI.Repo.preload transaction_entry, [:payment_transactions]
              Explorer.create_payment(transaction_entry.hash, payment_map(txn))
            :blockchain_txn_add_gateway_v1 ->
              txn_map =
                %{type: "gateway",
                  hash: Base.encode16(:blockchain_txn_add_gateway_v1.hash(txn), case: :lower)}
              {:ok, transaction_entry} = Explorer.create_transaction(height, txn_map)
              BlockchainAPI.Repo.preload transaction_entry, [:gateway_transactions]
              Explorer.create_gateway(transaction_entry.hash, gateway_map(txn))
            :blockchain_txn_assert_location_v1 ->
              txn_map =
                %{type: "location",
                  hash: Base.encode16(:blockchain_txn_assert_location_v1.hash(txn), case: :lower)}
              {:ok, transaction_entry} = Explorer.create_transaction(height, txn_map)
              BlockchainAPI.Repo.preload transaction_entry, [:location_transactions]
              Explorer.create_location(transaction_entry.hash, location_map(txn))
            _ ->
              :ok
          end
        end)
    end
  end

  defp coinbase_map(txn) do
    %{
      payee: to_string(:libp2p_crypto.address_to_b58(:blockchain_txn_coinbase_v1.payee(txn))),
      amount: :blockchain_txn_coinbase_v1.amount(txn)
    }
  end

  defp block_map(block) do
    height = :blockchain_block.height(block)
    hash = :blockchain_block.hash_block(block) |> Base.encode16(case: :lower)
    time = :blockchain_block.meta(block).block_time
    round = :blockchain_block.meta(block).hbbft_round
    %{hash: hash, height: height, time: time, round: round}
  end

  defp payment_map(txn) do
    %{
      payee: to_string(:libp2p_crypto.address_to_b58(:blockchain_txn_payment_v1.payee(txn))),
      payer: to_string(:libp2p_crypto.address_to_b58(:blockchain_txn_payment_v1.payer(txn))),
      amount: :blockchain_txn_payment_v1.amount(txn),
      nonce: :blockchain_txn_payment_v1.nonce(txn),
      fee: :blockchain_txn_payment_v1.fee(txn),
    }
  end

  defp gateway_map(txn) do
    %{
      owner: to_string(:libp2p_crypto.address_to_b58(:blockchain_txn_add_gateway_v1.owner_address(txn))),
      gateway: to_string(:libp2p_crypto.address_to_b58(:blockchain_txn_add_gateway_v1.gateway_address(txn))),
    }
  end

  defp location_map(txn) do
    %{
      owner: to_string(:libp2p_crypto.address_to_b58(:blockchain_txn_assert_location_v1.owner_address(txn))),
      gateway: to_string(:libp2p_crypto.address_to_b58(:blockchain_txn_assert_location_v1.gateway_address(txn))),
      nonce: :blockchain_txn_assert_location_v1.nonce(txn),
      fee: :blockchain_txn_assert_location_v1.fee(txn),
      location: to_string(:h3.to_string(:blockchain_txn_assert_location_v1.location(txn))),
    }
  end

end
