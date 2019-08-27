defmodule BlockchainAPI.HotspotNotifier do
  alias BlockchainAPI.{NotifierClient, Schema.Hotspot, Util}

  def send_new_hotspot_notification(txn, type, ledger) do
    map = Hotspot.map(type, txn, ledger)
    NotifierClient.post(data(map), message(map))
  end

  defp data(hotspot) do
    %{
      address: Util.bin_to_string(hotspot.address),
      owner: Util.bin_to_string(hotspot.owner)
    }
  end

  defp message(hotspot) do
    animal_name = Hotspot.animal_name(hotspot.address)
    "#{animal_name} has been added to the network!"
  end
end
