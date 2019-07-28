defmodule BlockchainAPI.Watcher do
  use GenServer
  alias BlockchainAPI.{Query, Committer}

  @me __MODULE__
  require Logger

  #==================================================================
  # API
  #==================================================================
  def start_link(args) do
    GenServer.start_link(@me, args, name: @me)
  end

  #==================================================================
  # GenServer Callbacks
  #==================================================================
  @impl true
  def init(args) do
    :ok = :blockchain_event.add_handler(self())
    schedule_check()
    {:ok, %{has_chain: false, env: Keyword.get(args, :env)}}
  end

  @impl true
  def handle_info(_, %{:env => :test}=state) do
    # Do nothing for test environment
    {:noreply, state}
  end

  @impl true
  def handle_info(:check, %{:has_chain => false, :env => env}=state) do
    case load_chain(env) do
      {:ok, true} ->
        {:noreply, Map.put(state, :has_chain, check_chain?())}
      {:error, false} ->
        schedule_check()
        {:noreply, state}
    end
  end
  def handle_info(:check, state) do
    Logger.debug("Already have chain")
    {:noreply, state}
  end

  @impl true
  def handle_info({:blockchain_event, {:integrate_genesis_block, {:ok, genesis_hash}}}, state) do
    Logger.info("Got integrate_genesis_block event")
    chain = :blockchain_worker.blockchain()
    ledger = :blockchain.ledger(chain)
    {:ok, block} = :blockchain.get_block(genesis_hash, chain)
    add_block(block, chain, ledger)
    {:noreply, Map.put(state, :has_chain, true)}
  end

  @impl true
  def handle_info({:blockchain_event, {:add_block, hash, _flag, ledger}}, state) do
    chain = :blockchain_worker.blockchain()
    {:ok, block} = :blockchain.get_block(hash, chain)
    add_block(block, chain, ledger)
    {:noreply, state}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.info("Unknown msg: #{inspect(msg)}")
    {:noreply, state}
  end

  #==================================================================
  # Private Functions
  #==================================================================
  defp add_block(block, chain, ledger) do
    height = :blockchain_block.height(block)
    try do
      Query.Block.get!(height)
    rescue
      _error in Ecto.NoResultsError ->
        case Query.Block.get_latest() do
          [nil] ->
            # nothing in the db yet
            Committer.commit(block, ledger, height)
          [last_known_height] ->
            case height > last_known_height do
              true ->
                Range.new(last_known_height + 1, height)
                |> Enum.map(fn h ->
                  {:ok, b} = :blockchain.get_block(h, chain)
                  h = :blockchain_block.height(b)
                  Committer.commit(b, ledger, h)
                end)
              false ->
                :ok
            end
        end
    end
  end

  defp load_chain(from_env) do
    genesis_file = Path.join([:code.priv_dir(:blockchain_api), "#{from_env}" , "genesis"])
    case File.read(genesis_file) do
      {:ok, genesis_block} ->
        :ok = genesis_block
              |> :blockchain_block.deserialize()
              |> :blockchain_worker.integrate_genesis_block()
        Logger.info("Successfully loaded genesis file")
        {:ok, true}
      {:error, reason} ->
        Logger.error("Unable to read genesis file, #{inspect(reason)}")
        {:error, false}
    end
  end

  defp check_chain?() do
    :blockchain_worker.blockchain() != :undefined
  end

  defp schedule_check() do
    # Check for chain after 5s of booting
    Process.send_after(self(), :check, :timer.seconds(5))
  end

end
