defmodule BlockchainAPIWeb.WitnessController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.Query
  alias BlockchainAPIWeb.WitnessView

  action_fallback BlockchainAPIWeb.FallbackController

  def show(conn, %{"name"  => name} = _params) do
    conn
    |> put_view(WitnessView)
    |> render("show.json", witnesses: witnesses(name))
  end

  defp witnesses(name) do
    addr = get_addr(name)
    case addr do
      [] -> []
      [a] ->
        get_witnesses(a)
      _ ->
        []
    end
  end

  defp get_addr(name) do
    name = name
           |> IO.inspect
           |> String.split("-")
           |> IO.inspect
           |> Enum.map(&String.capitalize/1)
           |> IO.inspect
           |> Enum.join(" ")
    addr = Query.Hotspot.get_addr_from_name(name)
    IO.inspect(addr)
    addr
  end

  defp get_witnesses(addr) do
    witnesses = :blockchain_worker.blockchain()
                |> IO.inspect
                |> :blockchain.ledger()
                |> IO.inspect
                |> :blockchain_ledger_v1.active_gateways()
                |> IO.inspect
                |> Map.get(addr)
                |> IO.inspect
                |> :blockchain_ledger_gateway_v2.witnesses()
                |> Map.to_list()
                |> Enum.reduce(
                  [],
                  fn({addr, _witness}, acc) ->
                    [BlockchainAPI.Schema.Hotspot.animal_name(addr) | acc]
                  end)
    IO.inspect(witnesses, label: :witnesses)
    witnesses
  end
end
