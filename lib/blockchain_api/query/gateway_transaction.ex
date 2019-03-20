defmodule BlockchainAPI.Query.GatewayTransaction do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{
    Repo,
    Util,
    Schema.GatewayTransaction,
    Schema.LocationTransaction
  }

  def list(params) do
    query = from(
      g in GatewayTransaction,
      left_join: l in LocationTransaction,
      on: g.gateway == l.gateway,
      select: %{
        gateway: g.gateway,
        gateway_hash: g.hash,
        owner: g.owner,
        fee: g.fee,
        location: l.location,
        location_fee: l.fee,
        location_nonce: l.nonce,
        location_hash: l.hash
      }
    )

    query
    |> Repo.paginate(params)
    |> clean_gateways()
  end

  def get!(hash) do
    GatewayTransaction
    |> where([gt], gt.hash == ^hash)
    |> Repo.one!
  end

  def create(attrs \\ %{}) do
    %GatewayTransaction{}
    |> GatewayTransaction.changeset(attrs)
    |> Repo.insert()
  end

  #==================================================================
  # Helper functions
  #==================================================================
  defp clean_gateways(%Scrivener.Page{entries: entries}=page) do
    data = entries
           |> Enum.map(fn map ->
             {lat, lng} = Util.h3_to_lat_lng(map.location)
             map
             |> encoded_gateway_map()
             |> Map.merge(%{lat: lat, lng: lng})
           end)

    %{page | entries: data}
  end

  defp encoded_gateway_map(map) do
    %{map |
      gateway: Util.bin_to_string(map.gateway),
      gateway_hash: Util.bin_to_string(map.gateway_hash),
      location_hash: Util.bin_to_string(map.location_hash),
      owner: Util.bin_to_string(map.owner)
    }
  end
end
