defmodule BlockchainAPIWeb.AccountSocket do
  use Phoenix.Socket

  channel "block:*", BlockchainAPIWeb.BlockChannel
  channel "account:*", BlockchainAPIWeb.AccountChannel

  def connect(_params, socket, _connect_info) do
    {:ok, socket}
  end

  def id(_socket), do: nil
end
