defmodule BlockchainAPIWeb.AccountChannel do
  use BlockchainAPIWeb, :channel

  def join("account:" <> account_address, _params, socket) do
    {:ok, %{channel: "account:#{account_address}"}, assign(socket, :account_address, account_address)}
  end

  def broadcast_change(account) do
    payload = %{
      address: account.address,
      name: account.name,
      balance: account.balance
    }

    BlockchainAPIWeb.Endpoint.broadcast("account:#{account.address}", "change", payload)
  end

end
