defmodule BlockchainAPI.Util do
  def bin_to_string(nil), do: nil
  def bin_to_string(bin) do
    bin
    |> :libp2p_crypto.bin_to_b58()
    |> to_string
  end

  def string_to_bin(nil), do: nil
  def string_to_bin(string) do
    string
    |> to_charlist()
    |> :libp2p_crypto.b58_to_bin()
  end

  def h3_to_lat_lng(nil), do: {nil, nil}
  def h3_to_lat_lng(loc) do
    loc
    |> String.to_charlist()
    |> :h3.from_string()
    |> :h3.to_geo()
  end

  def h3_to_string(nil), do: nil
  def h3_to_string(location) do
      to_string(:h3.to_string(location))
  end

  def reverse_geocode(loc) do
    {lat, lng} = h3_to_lat_lng(h3_to_string(loc))

    case HTTPoison.get("https://maps.googleapis.com/maps/api/geocode/json?latlng=#{lat},#{lng}&key=#{Application.get_env(:blockchain_api, :google_maps_secret)}") do
      {:ok, %{status_code: 200, body: body}} ->
        decoded_body = Jason.decode!(body)
        case hd(decoded_body["results"]) do
          %{"address_components" => address_components} ->
            street = Enum.find(address_components, fn c -> c["types"] == ["route"] end)["long_name"] || "Unknown"
            city = Enum.find(address_components, fn c -> c["types"] == ["locality", "political"] end)["long_name"] || "Unknown"
            state = Enum.find(address_components, fn c -> c["types"] == ["administrative_area_level_1", "political"] end)["long_name"] || "Unknown"
            country = Enum.find(address_components, fn c -> c["types"] == ["country", "political"] end)["short_name"] || "Unknown"
            {:ok, {street, city, state, country}}
          _ ->
            {:error, :unknown_location}
        end
      _ ->
        {:error, :bad_response}
    end
  end
end
