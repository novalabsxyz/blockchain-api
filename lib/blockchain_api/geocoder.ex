defmodule BlockchainAPI.Geocoder do
  @max_retries 5
  require Logger

  alias BlockchainAPI.Util

  def reverse_geocode(loc) do
    reverse_geocode(loc, @max_retries)
  end

  def reverse_geocode(loc, 0) do
    Logger.error("Exceeded google maps lookup for #{inspect(loc)}")
    {:error, :retries_exceeded}
  end

  def reverse_geocode(loc, retry) do
    {lat, lng} = Util.h3_to_lat_lng(Util.h3_to_string(loc))
    api_key = Application.get_env(:blockchain_api, :google_maps_secret)
    url = "https://maps.googleapis.com/maps/api/geocode/json?latlng=#{lat},#{lng}&key=#{api_key}"

    case HTTPoison.get(url, [], ssl: [{:honor_cipher_order, :undefined}]) do
      {:ok, %{status_code: 200, body: body}} ->
        decoded_body = Jason.decode!(body)
        results = Map.get(decoded_body, "results")

        case results do
          nil ->
            reverse_geocode(loc, retry - 1)

          [] ->
            reverse_geocode(loc, retry - 1)

          res ->
            parse_results(res)
        end

      _ ->
        reverse_geocode(loc, retry - 1)
    end
  end

  def parse_results(results) do
    case hd(results) do
      %{"address_components" => address_components} ->
        {:ok,
         %{
           long_street: parse_street(address_components, :long),
           short_street: parse_street(address_components, :short),
           long_city: parse_city(address_components, :long),
           short_city: parse_city(address_components, :short),
           long_state: parse_state(address_components, :long),
           short_state: parse_state(address_components, :short),
           long_country: parse_country(address_components, :long),
           short_country: parse_country(address_components, :short)
         }}
    end
  end

  defp parse_street(address_components, variant) do
    find_component(address_components, variant, ["route"])
  end

  defp parse_city(address_components, variant) do
    find_component(address_components, variant, ["locality", "sublocality"])
  end

  defp parse_state(address_components, variant) do
    find_component(address_components, variant, ["administrative_area_level_1"])
  end

  defp parse_country(address_components, variant) do
    find_component(address_components, variant, ["country"])
  end

  defp find_component(_components, _variant, types) when length(types) == 0 do
    "Unknown"
  end

  defp find_component(components, variant, [type | rest]) do
    case Enum.find(components, fn c -> type in c["types"] end) do
      nil ->
        find_component(components, variant, rest)

      component ->
        parse_component(component, variant)
    end
  end

  defp parse_component(component, variant) do
    case variant do
      :short -> component["short_name"]
      :long -> component["long_name"]
    end
  end
end
