defmodule BlockchainAPIWeb.ElectionTransactionController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.Query

  action_fallback BlockchainAPIWeb.FallbackController

  def index(conn, params) do
    consensus_groups = Query.ElectionTransaction.list(params)
    render(conn, "index.json", groups: consensus_groups)
  end
end
