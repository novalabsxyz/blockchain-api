defmodule BlockchainAPIWeb.NotificationController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.{Util, Query}
  import BlockchainAPI.Cache.CacheService

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, %{"account_address" => address} = params) do
    notifications = Query.Notification.list(address, params)

    conn
    |> put_cache_headers(ttl: :short, key: "block")
    |> render("index.json", notifications: notifications)
  end

  def create(conn, %{"notification" => notification_params}) do
    {:ok, notification} = Query.Notification.create(notification_params)

    conn
    |> render("show.json", notification: notification)
  end
end
