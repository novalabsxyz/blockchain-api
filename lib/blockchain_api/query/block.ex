defmodule BlockchainAPI.Query.Block do
  @moduledoc false
  import Ecto.Query, warn: false

  @default_limit 100
  @max_limit 1000

  alias BlockchainAPI.{
    Repo,
    Util,
    Schema.Block,
    Schema.Transaction,
    Cache
  }

  #==================================================================
  # Public functions
  #==================================================================
  def list(params) do
    list_query()
    |> maybe_filter(params)
    |> Repo.all()
    |> encode()
  end

  def get(height) do
    Cache.Util.get(:block_cache, height, &set_height/1, :timer.hours(24))
  end

  def create(attrs \\ %{}) do
    %Block{}
    |> Block.changeset(attrs)
    |> Repo.insert()
  end

  def get_latest_height() do
    query = from b in Block, select: max(b.height)
    Repo.one(query)
  end

  #==================================================================
  # Helper functions
  #==================================================================
  # Cache helpers
  def set_height(height) do
    data = get_by_height(height)
    {:commit, data}
  end

  defp get_by_height(height) do
    query = from(
      block in Block,
      full_join: txn in Transaction,
      on: block.height == txn.block_height,
      where: block.height == ^height,
      group_by: block.id,
      order_by: [desc: block.height],
      select: %{
        hash: block.hash,
        height: block.height,
        time: block.time,
        round: block.round,
        txns: count(txn.id)
      })

    query |> Repo.one() |> encode()
  end

  # Encoding helpers
  defp encode(nil), do: nil
  defp encode(%{hash: hash}=block) do
    %{block | hash: Util.bin_to_string(hash)}
  end
  defp encode(entries) when is_list(entries) do
    entries
    |> Enum.map(fn %{hash: hash}=block ->
      %{block | hash: Util.bin_to_string(hash)}
    end)
  end

  # Query helpers
  defp list_query() do
    from(
      block in Block,
      full_join: txn in Transaction,
      on: block.height == txn.block_height,
      group_by: block.id,
      order_by: [desc: block.height],
      select: %{
        hash: block.hash,
        height: block.height,
        time: block.time,
        round: block.round,
        txns: count(txn.id)
      })
  end

  defp maybe_filter(query, %{"before" => before, "limit" => limit0}=_params) do
    limit = min(@max_limit, String.to_integer(limit0))
    query
    |> where([block], block.height < ^before)
    |> limit(^limit)
  end
  defp maybe_filter(query, %{"before" => before}=_params) do
    query
    |> where([block], block.height < ^before)
    |> limit(@default_limit)
  end
  defp maybe_filter(query, %{"limit" => limit0}=_params) do
    limit = min(@max_limit, String.to_integer(limit0))
    query
    |> limit(^limit)
  end
  defp maybe_filter(query, %{}) do
    query
    |> limit(@default_limit)
  end
end
