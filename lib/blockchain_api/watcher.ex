defmodule BlockchainAPI.Watcher do
  use GenServer
  alias BlockchainAPI.{
    Committer,
    Query
  }

  alias BlockchainAPI.Cache.CacheService

  @me __MODULE__
  require Logger

  # ==================================================================
  # API
  # ==================================================================
  def start_link(args) do
    GenServer.start_link(@me, args, name: @me)
  end

  def chain() do
    GenServer.call(@me, :chain, :infinity)
  end

  def height() do
    GenServer.call(@me, :height, :infinity)
  end

  # ==================================================================
  # GenServer Callbacks
  # ==================================================================
  @impl true
  def init(args) do
    :ok = :blockchain_event.add_handler(self())
    state = init_state(args)
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
  def handle_info(
        {:blockchain_event, {:integrate_genesis_block, {:ok, genesis_hash}}},
        %{env: env} = state
      ) do
    Logger.info("Got integrate_genesis_block event")
    chain = :blockchain_worker.blockchain()
    ledger = :blockchain.ledger(chain)
    {:ok, block} = :blockchain.get_block(genesis_hash, chain)
    add_block(block, chain, ledger, true, env)
    {:noreply, Map.put(state, :chain, chain)}
  end

  @impl true
  def handle_info(
        {:blockchain_event, {:add_block, hash, sync_flag, ledger}},
        state = %{chain: chain, env: env}
      )
  when chain != nil do

    case Application.get_env(:blockchain_api, :ro_mode, 1) do
      1 ->
        {:noreply, state}
      _ ->
        {:ok, block} = :blockchain.get_block(hash, chain)
        add_block(block, chain, ledger, sync_flag, env)
        {:noreply, state}
    end
  end

  @impl true
  def handle_info(_, state) do
    {:noreply, state}
  end

  # ==================================================================
  # Private Functions
  # ==================================================================
  defp add_block(block, chain, ledger, sync_flag, env) do
    height = :blockchain_block.height(block)

    case Query.Block.get_latest_height() do
      nil ->
        # nothing in the db yet
        Committer.commit(block, ledger, height, sync_flag, env)

      last_known_height ->
        case height > last_known_height do
          true ->
            # purge the cache first so that when ws clients are
            # notified of a new block, they'll have fresh data
            if !sync_flag, do: CacheService.purge_key("block")

            Range.new(last_known_height + 1, height)
            |> Enum.map(fn h ->
              {:ok, b} = :blockchain.get_block(h, chain)
              h = :blockchain_block.height(b)
              Committer.commit(b, ledger, h, sync_flag, env)
            end)

          false ->
            :ok
        end
    end
  end

  defp load_chain(genesis_file) do
    case File.read(genesis_file) do
      {:ok, genesis_block} ->
        :ok =
          genesis_block
          |> :blockchain_block.deserialize()
          |> :blockchain_worker.integrate_genesis_block()

        :blockchain_worker.blockchain()

      {:error, _reason} ->
        nil
    end
  end

  defp init_state(args) do
    case Keyword.get(args, :env) do
      :test ->
        genesis_file = Path.join([:code.priv_dir(:blockchain_api), "test", "genesis"])
        %{chain: load_chain(genesis_file), env: :test}

      :dev ->
        genesis_file = Path.join([:code.priv_dir(:blockchain_api), "dev", "genesis"])
        %{chain: load_chain(genesis_file), env: :dev}

      :prod ->
        genesis_file = Path.join([:code.priv_dir(:blockchain_api), "prod", "genesis"])
        %{chain: load_chain(genesis_file), env: :prod}

      :pescadero ->
        genesis_file = Path.join([:code.priv_dir(:blockchain_api), "pescadero", "genesis"])
        %{chain: load_chain(genesis_file), env: :pescadero}
    end
  end

end
