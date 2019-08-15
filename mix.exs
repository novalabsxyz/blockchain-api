defmodule BlockchainAPI.MixProject do
  use Mix.Project

  def project do
    [
      app: :blockchain_api,
      version: "0.1.0",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [
        :logger,
        :runtime_tools,
        :gpb,
        :intercept,
        :rand_compat,
        :libp2p,
        :observer,
        :wx,
        :inets,
        :xmerl,
        :timex,
        :httpoison,
        :erl_angry_purple_tiger
      ],
      included_applications: [:blockchain],
      mod: {BlockchainAPI.Application, []}
    ]
  end


  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support", "priv/tasks"]
  defp elixirc_paths(_), do: ["lib", "priv/tasks"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      # api requirements
      {:phoenix, "~> 1.4.0"},
      {:phoenix_pubsub, "~> 1.1"},
      {:phoenix_ecto, "~> 4.0"},
      {:ecto_sql, "~> 3.0", override: true},
      {:postgrex, ">= 0.0.0"},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},
      {:ranch, "~> 1.7.1", override: true},
      {:httpoison, "~> 1.4"},
      {:number, "~> 1.0"},
      {:honeydew, "~> 1.4.0"},

      # blockchain requirements
      {:distillery, "~> 2.0"},
      {:blockchain, git: "git@github.com:helium/blockchain-core.git", branch: "master"},
      {:cuttlefish, git: "https://github.com/helium/cuttlefish.git", branch: "develop", override: true},
      {:h3, git: "https://github.com/helium/erlang-h3.git", branch: "master"},
      {:cors_plug, "~> 2.0"},
      {:poison, "~> 3.1"},
      {:logger_file_backend, "~> 0.0.10"},
      {:lager, "3.6.7", [env: :prod, repo: "hexpm", hex: "lager", override: true, manager: :rebar3]},
      {:timex, "~> 3.1"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.drop", "ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
