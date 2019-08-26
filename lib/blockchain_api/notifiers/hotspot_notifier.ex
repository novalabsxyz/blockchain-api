defmodule BlockchainAPI.HotspotNotifier do
  alias BlockchainAPI.{
    Schema.Hotspot,
    Util
  }

  @notifier_client Application.fetch_env!(:blockchain_api, :notifier_client)

  def send_new_hotspot_notification(txn, type, ledger) do
    map = Hotspot.map(type, txn, ledger)
    data = %{address: Util.bin_to_string(map.address), owner: Util.bin_to_string(map.owner)}
    animal_name = Hotspot.animal_name(hotspot.address)
    message = "#{animal_name} has been added to the network!"
    @notifier_client.post(data, message)
  end

  def send_add_hotspot_failed(:timed_out, pending_gateway) do
    data = %{gateway: pending_gateway.gateway, owner: pending_gateway.owner}
    message = "Unable to Add Hotspot. Transaction Timed Out."
    @notifier_client.post(data, message)
  end

  def send_add_hotspot_failed(:already_exists, pending_gateway) do
    data = %{gateway: pending_gateway.gateway, owner: pending_gateway.owner}
    message = "Unable to Add Hotspot. Hotspot Already on Blockchain."
    @notifier_client.post(data, message)
  end

  def send_confirm_location_failed(pending_location) do
    data = %{gateway: pending_location.gateway, owner: pending_location.owner}
    animal_name = Hotspot.animal_name(pending_location)
    message = "#{animal_name} Added Without Location Information."
    @notifier_client.post(data, message)
  end
end
