defmodule BlockchainAPI.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # Blockchain Supervisor Options
    %{:secret => privkey, :public => pubkey} = :libp2p_crypto.generate_keys(:ecc_compact)
    sig_fun = :libp2p_crypto.mk_sig_fun(privkey)
    base_dir = ~c(data)
    seed_nodes = Application.fetch_env!(:blockchain, :seed_nodes)
    seed_node_dns = Application.fetch_env!(:blockchain, :seed_node_dns)
    seed_addresses = dns_to_addresses(seed_node_dns)

    blockchain_sup_opts = [
      {:key, {pubkey, sig_fun}},
      {:seed_nodes, seed_nodes ++ seed_addresses},
      {:port, 0},
      {:num_consensus_members, 7},
      {:base_dir, base_dir}
    ]

    env = Application.fetch_env!(:blockchain_api, :env)
    watcher_worker_opts = [{:env, env}]

    # List all child processes to be supervised
    children = [
      # Start the blockchain
      %{
        id: :blockchain_sup,
        start: {:blockchain_sup, :start_link, [blockchain_sup_opts]},
        restart: :permanent,
        type: :supervisor
      },
      # Start the Ecto repository
      BlockchainAPI.Repo,
      # Start the endpoint when the application starts
      BlockchainAPIWeb.Endpoint,
      # Starts a worker by calling: BlockchainAPI.Worker.start_link(arg)
      {BlockchainAPI.Watcher, watcher_worker_opts},
      {BlockchainAPI.TxnManager, []},
      {BlockchainAPI.Notifier, []},
      {BlockchainAPI.FakeRewarder, []},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BlockchainAPI.Supervisor]
    Supervisor.start_link(children, opts)
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

end
