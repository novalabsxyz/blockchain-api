use Mix.Config

config :appsignal, :config,
  name: "blockchain-api",
  push_api_key: System.get_env("APP_SIGNAL_API_KEY"),
  env: Mix.env
