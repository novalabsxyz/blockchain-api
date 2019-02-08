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

    resources "/transactions", TransactionController, only: [:index, :show], param: "hash"

    resources "/accounts", AccountController, only: [:index, :show], param: "address" do
      resources "/transactions", AccountTransactionController, only: [:index], param: "account_address"
    end

    resources "/gateways", GatewayController, only: [:index, :show], param: "gateway_hash"

    # resources "/coinbase_transactions", CoinbaseController, except: [:new, :edit, :delete, :update]
    # resources "/payment_transactions", PaymentController, except: [:new, :edit, :delete, :update]
    # resources "/gateway_transactions", GatewayController, except: [:new, :edit, :delete, :update]
    # resources "/location_transactions", LocationController, except: [:new, :edit, :delete, :update]

  end
end
