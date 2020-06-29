defmodule BlockchainAPI.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  # alias Honeydew.EctoPollQueue
  alias BlockchainAPI.Repo
  alias BlockchainAPI.Watcher
  alias BlockchainAPI.{PeriodicCleaner, PeriodicUpdater}
  alias BlockchainAPI.{Notifier, RewardsNotifier}
  # alias BlockchainAPI.Job.{SubmitPayment, SubmitGateway, SubmitLocation, SubmitCoinbase, SubmitOUI, SubmitSecExchange}
  # alias BlockchainAPI.Schema.{PendingPayment, PendingGateway, PendingLocation, PendingCoinbase, PendingOUI, PendingSecExchange}

  # import PendingPayment, only: [submit_payment_queue: 0]
  # import PendingGateway, only: [submit_gateway_queue: 0]
  # import PendingLocation, only: [submit_location_queue: 0]
  # import PendingCoinbase, only: [submit_coinbase_queue: 0]
  # import PendingOUI, only: [submit_oui_queue: 0]
  # import PendingSecExchange, only: [submit_sec_exchange_queue: 0]

  def start(_type, _args) do
    env = Application.get_env(:blockchain_api, :env, :test)

    blockchain_sup_opts = blockchain_sup_opts()

    watcher_worker_opts = [{:env, env}]

    children = children(env, blockchain_sup_opts, watcher_worker_opts)

    opts = [strategy: :one_for_one, name: BlockchainAPI.Supervisor]
    {:ok, sup} = Supervisor.start_link(children, opts)

    # start_honeydew_queues(env)

    {:ok, sup}
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    BlockchainAPIWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp dns_to_addresses(seed_node_dns) do
    List.flatten(
      for x <- :inet_res.lookup(seed_node_dns, :in, :txt),
          String.starts_with?(to_string(x), "blockchain-seed-nodes="),
          do: String.trim_leading(to_string(x), "blockchain-seed-nodes=")
    )
    |> List.to_string()
    |> String.split(",")
    |> Enum.map(&String.to_charlist/1)
  end

  # defp queue_args(:prod, schema) do
  #   # Check for new jobs every 120s, this query is frequent but quite inexpensive
  #   poll_interval = Application.get_env(:ecto_poll_queue, :interval, 120)
  #   [schema: schema, repo: Repo, poll_interval: poll_interval]
  # end

  # defp queue_args(_, schema) do
  #   # Check for test and dev env pending txns every 30 minutes
  #   # No need for prod level checking here
  #   poll_interval = Application.get_env(:ecto_poll_queue, :interval, 30)
  #   [schema: schema, repo: Repo, poll_interval: poll_interval]
  # end

  defp children(:prod, blockchain_sup_opts, watcher_worker_opts) do
    # Children to start in prod env
    [
      # Start the blockchain
      %{
        id: :blockchain_sup,
        start: {:blockchain_sup, :start_link, [blockchain_sup_opts]},
        restart: :permanent,
        type: :supervisor
      },
      # Start the Ecto repository, both master and replica
      Repo,
      Repo.replica,
      # Start the endpoint when the application starts
      BlockchainAPIWeb.Endpoint,
      # Starts a worker by calling: BlockchainAPI.Worker.start_link(arg)
      {Watcher, watcher_worker_opts},
      {PeriodicCleaner, []},
      {PeriodicUpdater, []},
      {Notifier, []},
      {RewardsNotifier, []}
    ]
  end
  defp children(_, blockchain_sup_opts, watcher_worker_opts) do
    # Children to start in test and dev
    [
      # Start the blockchain
      %{
        id: :blockchain_sup,
        start: {:blockchain_sup, :start_link, [blockchain_sup_opts]},
        restart: :permanent,
        type: :supervisor
      },
      # Start the Ecto repository
      Repo,
      # Start the endpoint when the application starts
      BlockchainAPIWeb.Endpoint,
      # Starts a worker by calling: BlockchainAPI.Worker.start_link(arg)
      {Watcher, watcher_worker_opts},
      {PeriodicCleaner, []},
      {PeriodicUpdater, []},
      {Notifier, []}
    ]
  end

  # defp start_honeydew_queues(env) do
  #   :ok =
  #     Honeydew.start_queue(submit_payment_queue(),
  #       queue: {EctoPollQueue, queue_args(env, PendingPayment)},
  #       failure_mode: Honeydew.FailureMode.Abandon
  #     )

  #   :ok = Honeydew.start_workers(submit_payment_queue(), SubmitPayment)

  #   :ok =
  #     Honeydew.start_queue(submit_gateway_queue(),
  #       queue: {EctoPollQueue, queue_args(env, PendingGateway)},
  #       failure_mode: Honeydew.FailureMode.Abandon
  #     )

  #   :ok = Honeydew.start_workers(submit_gateway_queue(), SubmitGateway)

  #   :ok =
  #     Honeydew.start_queue(submit_location_queue(),
  #       queue: {EctoPollQueue, queue_args(env, PendingLocation)},
  #       failure_mode: Honeydew.FailureMode.Abandon
  #     )

  #   :ok = Honeydew.start_workers(submit_location_queue(), SubmitLocation)

  #   :ok =
  #     Honeydew.start_queue(submit_coinbase_queue(),
  #       queue: {EctoPollQueue, queue_args(env, PendingCoinbase)},
  #       failure_mode: Honeydew.FailureMode.Abandon
  #     )

  #   :ok = Honeydew.start_workers(submit_coinbase_queue(), SubmitCoinbase)

  #   :ok =
  #     Honeydew.start_queue(submit_oui_queue(),
  #       queue: {EctoPollQueue, queue_args(env, PendingOUI)},
  #       failure_mode: Honeydew.FailureMode.Abandon
  #     )

  #   :ok = Honeydew.start_workers(submit_oui_queue(), SubmitOUI)

  #   :ok =
  #     Honeydew.start_queue(submit_sec_exchange_queue(),
  #       queue: {EctoPollQueue, queue_args(env, PendingSecExchange)},
  #       failure_mode: Honeydew.FailureMode.Abandon
  #     )

  #   :ok = Honeydew.start_workers(submit_sec_exchange_queue(), SubmitSecExchange)
  # end

  defp blockchain_sup_opts() do
    base_dir = Application.get_env(:blockchain, :base_dir, String.to_charlist("data"))
    swarm_key = to_charlist(:filename.join([base_dir, "blockchain_api", "swarm_key"]))
    :ok = :filelib.ensure_dir(swarm_key)

    {pubkey, ecdh_fun, sig_fun} =
      case :libp2p_crypto.load_keys(swarm_key) do
        {:ok, %{:secret => priv_key, :public => pub_key}} ->
          {pub_key, :libp2p_crypto.mk_ecdh_fun(priv_key), :libp2p_crypto.mk_sig_fun(priv_key)}

        {:error, :enoent} ->
          key_map =
            %{:secret => priv_key, :public => pub_key} =
            :libp2p_crypto.generate_keys(:ecc_compact)

          :ok = :libp2p_crypto.save_keys(key_map, swarm_key)
          {pub_key, :libp2p_crypto.mk_ecdh_fun(priv_key), :libp2p_crypto.mk_sig_fun(priv_key)}
      end

    seed_nodes = Application.get_env(:blockchain, :seed_nodes, [])
    seed_node_dns = Application.get_env(:blockchain, :seed_node_dns, '')
    seed_addresses = dns_to_addresses(seed_node_dns)

    [
      {:key, {pubkey, sig_fun, ecdh_fun}},
      {:seed_nodes, seed_nodes ++ seed_addresses},
      {:port, 0},
      {:num_consensus_members, 7},
      {:base_dir, base_dir}
    ]
  end

end
