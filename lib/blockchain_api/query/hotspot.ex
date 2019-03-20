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

  def search(query_string, params) do
    search(query_string, @threshold, params)
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

  def search(query_string, threshold, params) do
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
        levenshtein(hotspot.long_country, ^query_string, ^threshold),
        order_by:
        fragment(
          "LEAST(?, ?, ?, ?, ?, ?, ?, ?)",
          levenshtein(hotspot.short_city, ^query_string),
          levenshtein(hotspot.long_city, ^query_string),
          levenshtein(hotspot.short_street, ^query_string),
          levenshtein(hotspot.long_street, ^query_string),
          levenshtein(hotspot.short_state, ^query_string),
          levenshtein(hotspot.long_state, ^query_string),
          levenshtein(hotspot.short_country, ^query_string),
          levenshtein(hotspot.long_country, ^query_string)
        )
      )

    query |> Repo.paginate(params)
  end
end
