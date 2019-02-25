defmodule BlockchainAPIWeb.BlockChannel do
  use BlockchainAPIWeb, :channel
  alias BlockchainAPI.Explorer.Block

  def join("block:update", _params, socket) do
    {:ok, %{data: "joined block:update"}, socket}
  end

  def broadcast_change(block) do
    payload = block |> Block.encode_model()
    BlockchainAPIWeb.Endpoint.broadcast("block:update", "change", payload)
  end

end
