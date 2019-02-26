defmodule BlockchainAPI.Watcher do
  use GenServer
  alias BlockchainAPI.{Explorer, Committer}

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
  defp add_block(block, chain) do
    height = :blockchain_block.height(block)
    try do
      Explorer.get_block!(height)
    rescue
      _error in Ecto.NoResultsError ->
        case Explorer.get_latest_block() do
          [nil] ->
            # nothing in the db yet
            commit_block(block, chain)
          [last_known_height] ->
            case height > last_known_height do
              true ->
                Range.new(last_known_height + 1, height)
                |> Enum.map(fn h ->
                  {:ok, b} = :blockchain.get_block(h, chain)
                  commit_block(b, chain)
                end)
              false ->
                :ok
            end
        end
    end
  end

  #==================================================================
  # Add block with subsequent updates to account and transactions
  #==================================================================
  defp commit_block(block, chain) do
    case Committer.commit(block, chain) do
      {:ok, _res} ->
        Logger.info("Successfully committed block at height: #{:blockchain_block.height(block)} to db!")
      {:error, reason} ->
        Logger.error("Error commiting block to db, #{reason}")
    end
  end
end
