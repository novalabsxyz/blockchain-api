defmodule BlockchainAPIWeb.HistoryController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.Query

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, %{"from" => from, "to" => to}=params) do
    history = Query.History.get(from, to, params)

    render(conn,
      "index.json",
      history: history
    )
  end
end
