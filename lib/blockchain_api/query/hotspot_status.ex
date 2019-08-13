defmodule BlockchainAPI.Query.HotspotStatus do
  @moduledoc ~s(Get hotspot status using libp2p peer information)

  require Logger

  def consolidate_status(challenge_status, pubkey_bin) do
    case challenge_status do
      "online" ->
        "online"
      "offline" ->
        case get_staleness(pubkey_bin) do
          {:error, _} ->
            "offline"
          {:ok, true} ->
            "offline"
          {:ok, false} ->
            "online"
        end
    end
  end

  def get_staleness(pubkey_bin) do
    swarm = :blockchain_swarm.swarm()
    pb = :libp2p_swarm.peerbook(swarm)
    case :libp2p_peerbook.get(pb, pubkey_bin) do
      {:error, reason}=e ->
        Logger.error("Peer not found #{inspect(reason)}")
        e
      {:ok, peer} ->
        ts = :libp2p_peer.timestamp(peer)
        is_stale = :libp2p_peer.is_stale(peer, ts)
        {:ok, not(is_stale)}
    end
  end

end
