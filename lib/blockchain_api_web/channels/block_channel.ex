defmodule BlockchainAPIWeb.BlockChannel do
  use BlockchainAPIWeb, :channel

  def join("block:update", _params, socket) do
    {:ok, %{data: "joined block:update"}, socket}
  end

end
