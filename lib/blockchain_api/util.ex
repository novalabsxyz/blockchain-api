defmodule BlockchainAPI.Util do

  alias BlockchainAPI.Schema.{
    PaymentTransaction,
    CoinbaseTransaction,
    SecurityTransaction,
    LocationTransaction,
    GatewayTransaction,
    POCRequestTransaction,
    POCReceiptsTransaction,
    PendingLocation,
    PendingGateway,
    PendingCoinbase,
    PendingPayment,
    ElectionTransaction
  }

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
            {:ok,
              %{
                long_street: Enum.find(address_components, fn c -> c["types"] == ["route"] end)["long_name"] || "Unknown",
                short_street: Enum.find(address_components, fn c -> c["types"] == ["route"] end)["short_name"] || "Unknown",
                long_city: Enum.find(address_components, fn c -> c["types"] == ["locality", "political"] end)["long_name"] || "Unknown",
                long_state: Enum.find(address_components, fn c -> c["types"] == ["administrative_area_level_1", "political"] end)["long_name"] || "Unknown",
                long_country: Enum.find(address_components, fn c -> c["types"] == ["country", "political"] end)["long_name"] || "Unknown",
                short_city: Enum.find(address_components, fn c -> c["types"] == ["locality", "political"] end)["short_name"] || "Unknown",
                short_state: Enum.find(address_components, fn c -> c["types"] == ["administrative_area_level_1", "political"] end)["short_name"] || "Unknown",
                short_country: Enum.find(address_components, fn c -> c["types"] == ["country", "political"] end)["short_name"] || "Unknown"
              }
            }
          _ ->
            {:error, :unknown_location}
        end
      _ ->
        {:error, :bad_response}
    end
  end

  def clean_txn_struct(%{pending_payment: payment}) when is_map(payment) do
    Map.merge(PendingPayment.encode_model(payment), %{type: "payment", height: nil, time: nil})
  end
  def clean_txn_struct(%{pending_coinbase: coinbase}) when is_map(coinbase) do
    Map.merge(PendingCoinbase.encode_model(coinbase), %{type: "coinbase", height: nil, time: nil})
  end
  def clean_txn_struct(%{pending_gateway: gateway}) when is_map(gateway) do
    Map.merge(PendingGateway.encode_model(gateway), %{type: "gateway", height: nil, time: nil})
  end
  def clean_txn_struct(%{pending_location: location}) when is_map(location) do
    {lat, lng} = h3_to_lat_lng(location.location)
    Map.merge(PendingLocation.encode_model(location), %{type: "location", lat: lat, lng: lng, height: nil, time: nil})
  end
  def clean_txn_struct(%{payment: payment, height: height, time: time}) when is_map(payment) do
    Map.merge(PaymentTransaction.encode_model(payment), %{type: "payment", height: height, time: time})
  end
  def clean_txn_struct(%{coinbase: coinbase, height: height, time: time}) when is_map(coinbase) do
    Map.merge(CoinbaseTransaction.encode_model(coinbase), %{type: "coinbase", height: height, time: time})
  end
  def clean_txn_struct(%{security: security, height: height, time: time}) when is_map(security) do
    Map.merge(SecurityTransaction.encode_model(security), %{type: "security", height: height, time: time})
  end
  def clean_txn_struct(%{election: election, height: height, time: time}) when is_map(election) do
    Map.merge(ElectionTransaction.encode_model(election), %{type: "election", height: height, time: time})
  end
  def clean_txn_struct(%{gateway: gateway, height: height, time: time}) when is_map(gateway) do
    Map.merge(GatewayTransaction.encode_model(gateway), %{type: "gateway", height: height, time: time})
  end
  def clean_txn_struct(%{location: location, height: height, time: time}) when is_map(location) do
    {lat, lng} = h3_to_lat_lng(location.location)
    Map.merge(LocationTransaction.encode_model(location), %{type: "location", lat: lat, lng: lng, height: height, time: time})
  end
  def clean_txn_struct(%{poc_request: poc_request, height: height, time: time}) when is_map(poc_request) do
    Map.merge(POCRequestTransaction.encode_model(poc_request), %{type: "poc_request", height: height, time: time})
  end
  def clean_txn_struct(%{poc_receipts: poc_receipts, height: height, time: time}) when is_map(poc_receipts) do
    Map.merge(POCReceiptsTransaction.encode_model(poc_receipts), %{type: "poc_receipts", height: height, time: time})
  end
  def clean_txn_struct(%{height: _height, time: _time}), do: nil
  def clean_txn_struct(map) when map == %{}, do: nil
end
