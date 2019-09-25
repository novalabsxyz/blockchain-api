defmodule BlockchainAPI.Query.Hotspot do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{
    Repo,
    Schema.Block,
    Schema.ConsensusMember,
    Schema.ElectionTransaction,
    Schema.Hotspot,
    Schema.POCReceipt,
    Schema.POCWitness,
    Schema.RewardTxn,
    Schema.Transaction,
    Util
  }

  # Default search levenshtein distance threshold
  @threshold 1

  def list(_params) do
    Hotspot
    |> order_by([h], desc: h.id)
    |> Repo.all()
  end

  def get!(address) do
    Hotspot
    |> where([h], h.address == ^address)
    |> Repo.one!()
  end

  def create(attrs \\ %{}) do
    %Hotspot{}
    |> Hotspot.changeset(attrs)
    |> Repo.insert()
  end

  def update!(hotspot, attrs \\ %{}) do
    hotspot
    |> Hotspot.changeset(attrs)
    |> Repo.update!()
  end

  def all() do
    Hotspot
    |> order_by([h], desc: h.id)
    |> Repo.all()
  end

  def all_no_loc() do
    Hotspot
    |> where([h], is_nil(h.location))
    |> order_by([h], desc: h.id)
    |> Repo.all()
  end

  def stats(address) do
    address = Util.string_to_bin(address)

    %{
      challenges_completed: challenges_completed_stats(address),
      consensus_groups: consensus_groups_stats(address),
      hlm_earned: hlm_earned_stats(address),
      earning_percentile: earning_percentile_stats(address),
      challenges_witnessed: challenges_witnessed_stats(address),
      witnessed_percentile: witnessed_percentile_stats(address),
      furthest_witness: furthest_witness(address),
      furthest_witness_percentile: furthest_witness_percentile(address)
    }
  end

  defp challenges_completed_stats(address) do
    %{
      "24h" => challenges_completed(address, Util.shifted_unix_time(hours: -24)),
      "7d" => challenges_completed(address, Util.shifted_unix_time(days: -7)),
      "30d" => challenges_completed(address, Util.shifted_unix_time(days: -30)),
      "all_time" => challenges_completed(address),
    }
  end

  defp consensus_groups_stats(address) do
    %{
      "24h" => consensus_groups(address, Util.shifted_unix_time(hours: -24)),
      "7d" => consensus_groups(address, Util.shifted_unix_time(days: -7)),
      "30d" => consensus_groups(address, Util.shifted_unix_time(days: -30)),
      "all_time" => consensus_groups(address),
    }
  end

  defp hlm_earned_stats(address) do
    %{
      "24h" => hlm_earned(address, Util.shifted_unix_time(hours: -24)),
      "7d" => hlm_earned(address, Util.shifted_unix_time(days: -7)),
      "30d" => hlm_earned(address, Util.shifted_unix_time(days: -30)),
      "all_time" => hlm_earned(address),
    }
  end

  defp earning_percentile_stats(address) do
    %{
      "24h" => earning_percentile(address, Util.shifted_unix_time(hours: -24)),
      "7d" => earning_percentile(address, Util.shifted_unix_time(days: -7)),
      "30d" => earning_percentile(address, Util.shifted_unix_time(days: -30)),
      "all_time" => earning_percentile(address),
    }
  end

  defp challenges_witnessed_stats(address) do
    %{
      "24h" => challenges_witnessed(address, Util.shifted_unix_time(hours: -24)),
      "7d" => challenges_witnessed(address, Util.shifted_unix_time(days: -7)),
      "30d" => challenges_witnessed(address, Util.shifted_unix_time(days: -30)),
      "all_time" => challenges_witnessed(address),
    }
  end

  defp witnessed_percentile_stats(address) do
    %{
      "24h" => witnessed_percentile(address, Util.shifted_unix_time(hours: -24)),
      "7d" => witnessed_percentile(address, Util.shifted_unix_time(days: -7)),
      "30d" => witnessed_percentile(address, Util.shifted_unix_time(days: -30)),
      "all_time" => witnessed_percentile(address),
    }
  end

  # Search hotspots with fuzzy str match with Levenshtein distance

  def search(query_string) do
    query_string
    |> search(@threshold)
    |> format()
  end

  defmacro levenshtein(str1, str2, threshold) do
    quote do
      levenshtein(unquote(str1), unquote(str2)) <= unquote(threshold)
    end
  end

  defmacro levenshtein(str1, str2) do
    quote do
      fragment(
        "levenshtein(LOWER(?), LOWER(?))",
        unquote(str1),
        unquote(str2)
      )
    end
  end

  defp search(query_string, threshold) do
    query_string = String.downcase(query_string)

    query =
      from(
        hotspot in Hotspot,
        where:
          levenshtein(hotspot.short_city, ^query_string, ^threshold) or
            levenshtein(hotspot.long_city, ^query_string, ^threshold) or
            levenshtein(hotspot.short_street, ^query_string, ^threshold) or
            levenshtein(hotspot.long_street, ^query_string, ^threshold) or
            levenshtein(hotspot.short_state, ^query_string, ^threshold) or
            levenshtein(hotspot.long_state, ^query_string, ^threshold) or
            levenshtein(hotspot.short_country, ^query_string, ^threshold) or
            levenshtein(hotspot.long_country, ^query_string, ^threshold) or
            ilike(hotspot.short_city, ^"%#{query_string}%") or
            ilike(hotspot.long_city, ^"%#{query_string}%") or
            ilike(hotspot.short_street, ^"%#{query_string}%") or
            ilike(hotspot.long_street, ^"%#{query_string}%") or
            ilike(hotspot.short_state, ^"%#{query_string}%") or
            ilike(hotspot.long_state, ^"%#{query_string}%") or
            ilike(hotspot.short_country, ^"%#{query_string}%") or
            ilike(hotspot.long_country, ^"%#{query_string}%"),
        select: %{
          long_city: hotspot.long_city,
          short_city: hotspot.short_city,
          short_state: hotspot.short_state,
          long_state: hotspot.long_state,
          short_country: hotspot.short_country,
          long_country: hotspot.long_country,
          location: hotspot.location
        }
      )

    query |> Repo.all()
  end

  defp format(entries) do
    city_counts =
      entries
      |> Enum.group_by(fn entry -> entry.long_city end)
      |> Enum.reduce(%{}, fn {k, v}, acc -> Map.put(acc, k, length(v)) end)

    entries
    |> Enum.reduce([], fn entry, acc ->
      [Map.merge(entry, %{:count => Map.get(city_counts, entry.long_city, 0)}) | acc]
    end)
    # TODO: The location returned uniquely is pretty much pointless
    # Ideally we'd want to use h3 and figure out a bounding box depending on the search criteria
    # And return something in the middle of that city.
    |> Enum.uniq_by(& &1.long_city)
    |> Enum.map(fn %{location: loc} = entry ->
      {lat, lng} = Util.h3_to_lat_lng(loc)

      entry
      |> Map.delete(:location)
      |> Map.merge(%{lat: lat, lng: lng})
    end)
    |> Enum.sort_by(& &1.count, &>=/2)
  end

  defp challenges_completed(address, start_time \\ 0) do
    from(
      pr in POCReceipt,
      where: pr.gateway == ^address,
      where: pr.timestamp >= ^start_time,
      select: count(pr.id)
    )
    |> Repo.one()
  end

  defp consensus_groups(address, start_time \\ 0) do
    from(
      cm in ConsensusMember,
      where: cm.address == ^address,
      inner_join: et in ElectionTransaction,
      on: cm.election_transactions_id == et.id,
      inner_join: t in Transaction,
      on: et.hash == t.hash,
      inner_join: b in Block,
      on: t.block_height == b.height,
      where: b.time >= ^start_time,
      select: count(cm.id)
    )
    |> Repo.one()
  end

  defp hlm_earned(address, start_time \\ 0) do
    from(
      rt in RewardTxn,
      where: rt.gateway == ^address,
      inner_join: t in Transaction,
      on: rt.rewards_hash == t.hash,
      inner_join: b in Block,
      on: t.block_height == b.height,
      where: b.time >= ^start_time,
      select: sum(rt.amount)
    )
    |> Repo.one()
  end

  defp earning_percentile(address, start_time \\ 0) do
    ranking =
      from(
        rt in RewardTxn,
        inner_join: t in Transaction,
        on: rt.rewards_hash == t.hash,
        inner_join: b in Block,
        on: t.block_height == b.height,
        where: b.time >= ^start_time,
        group_by: rt.gateway,
        order_by: [desc: sum(rt.amount)],
        select: rt.gateway
      )
      |> Repo.all()

    get_percentile(ranking, address)
  end

  defp challenges_witnessed(address, start_time \\ 0) do
    from(
      pw in POCWitness,
      where: pw.gateway == ^address,
      where: pw.timestamp >= ^start_time,
      select: count(pw.id)
    )
    |> Repo.one()
  end

  defp witnessed_percentile(address, start_time \\ 0) do
    ranking =
      from(
        pw in POCWitness,
        where: pw.timestamp >= ^start_time,
        group_by: pw.gateway,
        order_by: [desc: count(pw.id)],
        select: pw.gateway
      )
      |> Repo.all()

    get_percentile(ranking, address)
  end

  defp furthest_witness(address) do
    from(
      pw in POCWitness,
      where: pw.gateway == ^address,
      select: max(pw.distance)
    )
    |> Repo.one()
  end

  defp furthest_witness_percentile(address) do
    ranking =
      from(
        pw in POCWitness,
        group_by: pw.gateway,
        order_by: [desc: max(pw.distance)],
        select: pw.gateway
      )
      |> Repo.all()

    get_percentile(ranking, address)
  end

  defp get_percentile([], _), do: 0

  defp get_percentile(ranking, address) do
    case num_hotspots() do
      1 ->
        100

      n ->
        index = Enum.find_index(ranking, & &1 == address)
        (n - index - 1) / (n - 1)
        |> Kernel.*(100)
        |> Kernel.round()
    end
  end

  defp num_hotspots do
    from(
      h in Hotspot,
      select: count(h.id)
    )
    |> Repo.one()
  end
end
