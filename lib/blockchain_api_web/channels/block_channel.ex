defmodule BlockchainAPIWeb.BlockChannel do
  use BlockchainAPIWeb, :channel

  def join("block:update", _params, socket) do
    {:ok, %{data: "joined block:update"}, socket}
  end

  def broadcast_change(block) do
    payload = %{
      height: block.height,
      hash: block.hash,
      round: block.round,
      time: block.time
    }

    BlockchainAPIWeb.Endpoint.broadcast("block:update", "change", payload)
  end

end
