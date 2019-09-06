defmodule BlockchainAPI.Util do
  use Timex

  alias BlockchainAPI.Schema.{
    CoinbaseTransaction,
    DataCreditTransaction,
    ElectionTransaction,
    GatewayTransaction,
    LocationTransaction,
    PaymentTransaction,
    PendingCoinbase,
    PendingGateway,
    PendingLocation,
    PendingPayment,
    POCReceiptsTransaction,
    POCRequestTransaction,
    RewardsTransaction,
    SecurityTransaction
  }

  @bones 100_000_000
  @max_retries 5
  require Logger

  def rounder(nil, _) do
    nil
  end

  def rounder(value, precision) do
    Decimal.from_float(value)
    |> Decimal.round(precision)
    |> Decimal.to_float()
  end

  def bin_to_string(<<>>), do: nil
  def bin_to_string(:undefined), do: nil
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

  def h3_to_string(location) when is_integer(location) do
    to_string(:h3.to_string(location))
  end

  def h3_to_string(_), do: nil

  def h3_from_string(index) do
    index |> String.to_charlist() |> :h3.from_string()
  end

  def reverse_geocode(loc) do
    reverse_geocode(loc, @max_retries)
  end

  def reverse_geocode(loc, 0) do
    Logger.error("Exceeded google maps lookup for #{inspect(loc)}")
    {:error, :retries_exceeded}
  end

  def reverse_geocode(loc, retry) do
    {lat, lng} = h3_to_lat_lng(h3_to_string(loc))

    case HTTPoison.get(
           "https://maps.googleapis.com/maps/api/geocode/json?latlng=#{lat},#{lng}&key=#{
             Application.get_env(:blockchain_api, :google_maps_secret)
           }"
         ) do
      {:ok, %{status_code: 200, body: body}} ->
        decoded_body = Jason.decode!(body)

        case hd(decoded_body["results"]) do
          %{"address_components" => address_components} ->
            {:ok,
             %{
               long_street:
                 Enum.find(address_components, fn c -> c["types"] == ["route"] end)["long_name"] ||
                   "Unknown",
               short_street:
                 Enum.find(address_components, fn c -> c["types"] == ["route"] end)["short_name"] ||
                   "Unknown",
               long_city:
                 Enum.find(address_components, fn c -> c["types"] == ["locality", "political"] end)[
                   "long_name"
                 ] || "Unknown",
               long_state:
                 Enum.find(address_components, fn c ->
                   c["types"] == ["administrative_area_level_1", "political"]
                 end)["long_name"] || "Unknown",
               long_country:
                 Enum.find(address_components, fn c -> c["types"] == ["country", "political"] end)[
                   "long_name"
                 ] || "Unknown",
               short_city:
                 Enum.find(address_components, fn c -> c["types"] == ["locality", "political"] end)[
                   "short_name"
                 ] || "Unknown",
               short_state:
                 Enum.find(address_components, fn c ->
                   c["types"] == ["administrative_area_level_1", "political"]
                 end)["short_name"] || "Unknown",
               short_country:
                 Enum.find(address_components, fn c -> c["types"] == ["country", "political"] end)[
                   "short_name"
                 ] || "Unknown"
             }}

          _ ->
            reverse_geocode(loc, retry - 1)
            {:error, :unknown_location}
        end

      _ ->
        reverse_geocode(loc, retry - 1)
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

    Map.merge(PendingLocation.encode_model(location), %{
      type: "location",
      lat: lat,
      lng: lng,
      height: nil,
      time: nil
    })
  end

  def clean_txn_struct(%{payment: payment, height: height, time: time}) when is_map(payment) do
    Map.merge(PaymentTransaction.encode_model(payment), %{
      type: "payment",
      height: height,
      time: time
    })
  end

  def clean_txn_struct(%{coinbase: coinbase, height: height, time: time}) when is_map(coinbase) do
    Map.merge(CoinbaseTransaction.encode_model(coinbase), %{
      type: "coinbase",
      height: height,
      time: time
    })
  end

  def clean_txn_struct(%{security: security, height: height, time: time}) when is_map(security) do
    Map.merge(SecurityTransaction.encode_model(security), %{
      type: "security",
      height: height,
      time: time
    })
  end

  def clean_txn_struct(%{data_credit: data_credit, height: height, time: time})
      when is_map(data_credit) do
    Map.merge(DataCreditTransaction.encode_model(data_credit), %{
      type: "data_credit",
      height: height,
      time: time
    })
  end

  def clean_txn_struct(%{election: election, height: height, time: time}) when is_map(election) do
    Map.merge(ElectionTransaction.encode_model(election), %{
      type: "election",
      height: height,
      time: time
    })
  end

  def clean_txn_struct(%{gateway: gateway, height: height, time: time}) when is_map(gateway) do
    Map.merge(GatewayTransaction.encode_model(gateway), %{
      type: "gateway",
      height: height,
      time: time
    })
  end

  def clean_txn_struct(%{location: location, height: height, time: time}) when is_map(location) do
    {lat, lng} = h3_to_lat_lng(location.location)

    Map.merge(LocationTransaction.encode_model(location), %{
      type: "location",
      lat: lat,
      lng: lng,
      height: height,
      time: time
    })
  end

  def clean_txn_struct(%{poc_request: poc_request, height: height, time: time})
      when is_map(poc_request) do
    Map.merge(POCRequestTransaction.encode_model(poc_request), %{
      type: "poc_request",
      height: height,
      time: time
    })
  end

  def clean_txn_struct(%{poc_receipts: poc_receipts, height: height, time: time})
      when is_map(poc_receipts) do
    Map.merge(POCReceiptsTransaction.encode_model(poc_receipts), %{
      type: "poc_receipts",
      height: height,
      time: time
    })
  end

  def clean_txn_struct(%{rewards: rewards, height: height, time: time}) when is_map(rewards) do
    Map.merge(RewardsTransaction.encode_model(rewards), %{
      type: "rewards",
      height: height,
      time: time
    })
  end

  def clean_txn_struct(%{height: _height, time: _time}), do: nil
  def clean_txn_struct(map) when map == %{}, do: nil

  def ledger_nonce(address) do
    # TODO: Use the ledger at the time of adding the block
    ledger = :blockchain.ledger(:blockchain_worker.blockchain())

    case :blockchain_ledger_v1.find_entry(address, ledger) do
      {:error, _reason} ->
        # Return 0 if there is no entry in the ledger
        0

      {:ok, entry} ->
        :blockchain_ledger_entry_v1.nonce(entry)
    end
  end

  def current_time() do
    Timex.now() |> Timex.to_unix()
  end

  def shifted_unix_time(shift) do
    Timex.now() |> Timex.shift(shift) |> Timex.to_unix()
  end

  @pi_over_180 3.14159265359 / 180.0
  @radius_of_earth_meters 6_371_008.8

  @doc """
  Returns the distance in meters between two h3 indexes using the haversine formula.
  """
  def h3_distance_in_meters(h3_1, h3_2) do
    {lat1, lon1} = :h3.to_geo(h3_1)
    {lat2, lon2} = :h3.to_geo(h3_2)

    a = :math.sin((lat2 - lat1) * @pi_over_180 / 2)
    b = :math.sin((lon2 - lon1) * @pi_over_180 / 2)

    s = a * a + b * b * :math.cos(lat1 * @pi_over_180) * :math.cos(lat2 * @pi_over_180)
    2 * :math.atan2(:math.sqrt(s), :math.sqrt(1 - s)) * @radius_of_earth_meters
  end

  @doc """
  Fetch notifier client from app env.

  Due to the app being compiled, setting it as a module level param
  causes issues when building the app in different environments.
  """
  def notifier_client(), do: Application.fetch_env!(:blockchain_api, :notifier_client)

  defp delimit_unit(units0) do
    unit_str = units0 |> Decimal.to_string()

    case :binary.match(unit_str, ".") do
      {start, _} ->
        precision = byte_size(unit_str) - start - 1

        units0
        |> Decimal.to_float()
        |> Number.Delimit.number_to_delimited(precision: precision)
        |> String.trim_trailing("0")

      :nomatch ->
        units0
        |> Decimal.to_float()
        |> Number.Delimit.number_to_delimited(precision: 0)
    end
  end
end
