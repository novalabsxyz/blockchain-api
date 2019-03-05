defmodule BlockchainAPIWeb.Router do
  use BlockchainAPIWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", BlockchainAPIWeb do
    pipe_through :api

    resources "/blocks", BlockController, only: [:show, :index], param: "height" do
      resources "/transactions", TransactionController, only: [:index], param: "hash"
    end

    resources "/accounts", AccountController, only: [:index], param: "address" do
      resources "/transactions", AccountTransactionController, only: [:index], param: "account_address"
      resources "/gateways", AccountGatewayController, only: [:index], param: "account_address"
      resources "/pending_transactions", AccountPendingTransactionController, only: [:index], param: "account_address"
    end


    resources "/accounts", AccountBalanceController, only: [:show], param: "address"
    resources "/transactions", TransactionController, only: [:index, :show, :create], param: "hash"
    resources "/gateways", GatewayController, only: [:index, :show], param: "hash"
    resources "/coinbase_transactions", CoinbaseController, only: [:index, :show], param: "hash"
    resources "/payment_transactions", PaymentController, only: [:index, :show], param: "hash"
    resources "/gateway_transactions", GatewayController, only: [:index, :show], param: "hash"
    resources "/location_transactions", LocationController, only: [:index, :show], param: "hash"

  end

  scope "/", BlockchainAPIWeb do
    get "/", HealthCheckController, :index
  end
end
