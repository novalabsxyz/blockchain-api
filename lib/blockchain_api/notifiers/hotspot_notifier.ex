defmodule BlockchainAPI.HotspotNotifier do
  alias BlockchainAPI.{Schema.Hotspot, Util}

  def send_new_hotspot_notification(pending_gateway) do
    data = %{
      hotspot_address: Util.bin_to_string(pending_gateway.gateway),
      owner: Util.bin_to_string(pending_gateway.owner),
      hash: Util.bin_to_string(pending_gateway.txn),
      type: "addHotspotSuccess"
    }
    opts = %{external_id: UUID.uuid5(:oid, "#{pending_gateway.txn}success")}
    animal_name = Hotspot.animal_name(data.address)
    message = "#{animal_name} has been added to the network!"
    Util.notifier_client().post(data, message, data.owner, opts)
  end

  def send_add_hotspot_failed(:timed_out, pending_gateway) do
    data = %{
      hotspot_address: Util.bin_to_string(pending_gateway.gateway),
      owner: Util.bin_to_string(pending_gateway.owner),
      type: "addHotspotTimeOut"
    }
    opts = %{external_id: UUID.uuid5(:oid, "#{pending_gateway.txn}timed_out")}
    message = "Unable to Add Hotspot. Transaction Timed Out."
    Util.notifier_client().post(data, message, data.owner, opts)
  end

  def send_add_hotspot_failed(:already_exists, pending_gateway) do
    data = %{
      hotspot_address: Util.bin_to_string(pending_gateway.gateway),
      owner: Util.bin_to_string(pending_gateway.owner),
      type: "addHotspotAlreadyExists"
    }
    opts = %{external_id: UUID.uuid5(:oid, "#{pending_gateway.txn}already_exists")}
    message = "Unable to Add Hotspot. Hotspot Already on Blockchain."
    Util.notifier_client().post(data, message, data.owner, opts)
  end

  def send_confirm_location_failed(pending_location) do
    data = %{
      hotspot_address: Util.bin_to_string(pending_location.gateway),
      owner: Util.bin_to_string(pending_location.owner),
      type: "assertLocationFailure"
    }
    opts = %{external_id: UUID.uuid5(:oid, "#{pending_location.txn}failed")}
    animal_name = Hotspot.animal_name(pending_location)
    message = "#{animal_name} Added Without Location Information."
    Util.notifier_client().post(data, message, data.owner, opts)
  end
end
