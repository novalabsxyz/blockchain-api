defmodule BlockchainAPIWeb.WitnessController do
  use BlockchainAPIWeb, :controller

  alias BlockchainAPI.Util
  alias BlockchainAPIWeb.WitnessView

  action_fallback BlockchainAPIWeb.FallbackController

  def show(conn, %{"address"  => address} = _params) do
    conn
    |> put_view(WitnessView)
    |> render("show.json", witnesses: witnesses(address))
  end

  defp witnesses(address) do
    address
    |> Util.string_to_bin()
    |> get_witnesses()
  end

  defp get_witnesses(addr) do
    :blockchain_worker.blockchain()
    |> :blockchain.ledger()
    |> :blockchain_ledger_v1.active_gateways()
    |> Map.get(addr)
    |> :blockchain_ledger_gateway_v2.witnesses()
    |> Map.to_list()
    |> Enum.reduce(
      [],
      fn({_addr, _witness}=kv, acc) ->
        [encode_witness(kv) | acc]
      end)
  end

  defp encode_witness({addr, witness}) do

    hist =
      try do
        :blockchain_ledger_gateway_v2.witness_hist(witness)
      rescue
        _ ->
          %{}
      end

    first_time =
      case :blockchain_ledger_gateway_v2.witness_first_time(witness) do
        :undefined -> nil
        t -> t
      end

    recent_time =
      case :blockchain_ledger_gateway_v2.witness_recent_time(witness) do
        :undefined -> nil
        t -> t
      end

    %{
      name: BlockchainAPI.Schema.Hotspot.animal_name(addr),
      addr: Util.bin_to_string(addr),
      hist: hist,
      first_time: first_time,
      recent_time: recent_time
    }
  end

end
