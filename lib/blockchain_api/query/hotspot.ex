defmodule BlockchainAPI.Query.Hotspot do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.Hotspot}

  # Default search levenshtein distance threshold
  @threshold 1

  def list(params) do
    Hotspot
    |> order_by([h], [desc: h.id])
    |> Repo.paginate(params)
  end

  def get!(address) do
    Hotspot
    |> where([h], h.address == ^address)
    |> Repo.one!
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
        (unquote(str1)),
        (unquote(str2))
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
          long_country: hotspot.long_country
        }
      )

    query |> Repo.all()
  end

  defp format(entries) do
    city_map = entries |> Enum.group_by(fn(entry) -> entry.long_city end)

    city_counts = :maps.map(fn(_, v) -> length(v) end, city_map)

    entries
    |> Enum.reduce([], fn(entry, acc) ->
      [Map.merge(entry, %{:count => Map.get(city_counts, entry.long_city, 0)}) | acc]
    end)
    |> Enum.uniq()
    |> Enum.sort_by(&(&1.count), &>=/2)
  end
end
