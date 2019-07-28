defmodule BlockchainAPIWeb.AccountChannel do
  use BlockchainAPIWeb, :channel
  alias BlockchainAPI.Schema.Account
  alias BlockchainAPI.Util

  def join("account:" <> account_address, _params, socket) do
    {:ok, %{channel: "account:#{account_address}"},
     assign(socket, :account_address, account_address)}
  end

  def broadcast_change(account) do
    payload = account |> Account.encode_model()

    BlockchainAPIWeb.Endpoint.broadcast(
      "account:#{Util.bin_to_string(account.address)}",
      "change",
      payload
    )
  end
end
