defmodule BlockchainAPI.Query.AccountPendingTxn do
  @moduledoc false
  alias BlockchainAPI.{Query, Util}

  def list(address, _params) do
    # Get all pending transactions for the given account address
    # Pending txns currently supported:
    # - pending_gateway
    # - pending_location
    # - pending_sec_exchange
    # - pending_oui
    # - pending_payment
    # Ignores pending_coinbase (legacy and cannot actually be posted to api anyway)

    pgateways = Query.PendingGateway.get_by_owner(address)
    plocations = Query.PendingLocation.get_by_owner(address)
    psec_exchanges = Query.PendingSecExchange.get_by_address(address)
    pouis = Query.PendingOUI.get_by_owner(address)
    ppayments = Query.PendingPayment.get_by_address(address)

    result = pgateways ++ plocations ++ psec_exchanges ++ pouis ++ ppayments
    result |> encode()

  end

  # Encoding helpers
  defp encode(entries) do
    entries
    |> Enum.map(fn(t) -> Util.clean_txn_struct(t) end)
  end

end
