defmodule BlockchainAPI.Query.HotspotStatus do
  @moduledoc ~s(Get hotspot status using libp2p peer information)

  require Logger

  def get_status(pubkey_bin) do
    swarm = :blockchain_swarm.swarm()
    pb = :libp2p_swarm.peerbook(swarm)
    case :libp2p_peerbook.get(pb, pubkey_bin) do
      {:error, reason} ->
        Logger.error("Peer not found #{inspect(reason)}")
        %{}
      {:ok, peer} ->
        ts = :libp2p_peer.timestamp(peer)
        is_stale = :libp2p_peer.is_stale(peer, ts)
        %{
          is_stale: is_stale
        }
    end
  end

end
