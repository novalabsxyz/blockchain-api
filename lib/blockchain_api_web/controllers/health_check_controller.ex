defmodule BlockchainAPIWeb.HealthCheckController do
  use BlockchainAPIWeb, :controller

  def index(conn, params) do
    send_resp(conn, 200, "ok")
  end
end
