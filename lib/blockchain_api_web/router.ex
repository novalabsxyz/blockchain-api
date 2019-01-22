defmodule BlockchainAPIWeb.Router do
  use BlockchainAPIWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", BlockchainAPIWeb do
    pipe_through :api

    resources "/blocks", BlockController, except: [:new, :edit, :delete, :update]
    resources "/coinbase_transactions", CoinbaseController, except: [:new, :edit, :delete, :update]
    resources "/payment_transactions", PaymentController, except: [:new, :edit, :delete, :update]
    resources "/gateway_transactions", GatewayController, except: [:new, :edit, :delete, :update]
    resources "/location_transactions", LocationController, except: [:new, :edit, :delete, :update]

  end
end
