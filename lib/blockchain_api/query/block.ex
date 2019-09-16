defmodule BlockchainAPI.Query.Block do
  @moduledoc """
  Block query functions.
  """
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

  @doc """
  Get list of blocks with given `params`.

  `params` is a map of string keys limit and/or before.

  ## Examples

    iex> BlockchainAPI.Query.Block.list %{"limit" => "2", "before" => "10"}
      [
        %{
          hash: "12e33843hKKPTuVQkGA9h7Y2qZRsmmJEtXzym5GcJnMmUXqEGax",
          height: 9,
          time: 1564437093,
          txns: 0
        },
        %{
          hash: "1eVRXbseDhRJSSg3KnkCR5XSzsujET6GyNUzDE5dGrP9ro7cpW",
          height: 8,
          time: 1564437033,
          txns: 0
        }
      ]
  """
  def list(params) do
    {:blocks, blocks} =
      Cache.Util.get(:block_cache, {:blocks, params}, &set_list/1, :timer.minutes(2))

    blocks
  end

  @doc """
  Get block at given `height`

  ## Examples

    iex> BlockchainAPI.Query.Block.get(10)
      %{
        hash: "1NPjYurwS8LKRmSbpyvLXzb39qEUi8uAUpKdZ4Wf1MBefAAWst",
        height: 10,
        time: 1564437153,
        txns: 0
      }
  """
  def get(height) do
    Cache.Util.get(:block_cache, height, &set_height/1, :timer.minutes(2))
  end

  @doc """
  Get latest block height.

  ## Examples

    iex> BlockchainAPI.Query.Block.get_latest_height
      49362
  """
  def get_latest_height() do
    query = from b in Block, select: max(b.height)
    Repo.one(query)
  end

  @doc false
  def create(attrs \\ %{}) do
    %Block{}
    |> Block.changeset(attrs)
    |> Repo.insert()
  end

  # ==================================================================
  # Helper functions
  # ==================================================================
  # Cache helpers
  defp set_height(height) do
    data = get_by_height(height)
    {:commit, data}
  end

  defp set_list({:blocks, params}) do
    data =
      base_query()
      |> maybe_filter(params)
      |> Repo.all()
      |> encode()

    {:commit, {:blocks, data}}
  end

  defp get_by_height(height) do
    base_query()
    |> where([b], b.height == ^height)
    |> Repo.one()
    |> encode()
  end

  # Encoding helpers
  defp encode(nil), do: nil

  defp encode(%{hash: hash} = block) do
    %{block | hash: Util.bin_to_string(hash)}
  end

  defp encode(entries) when is_list(entries) do
    entries
    |> Enum.map(fn %{hash: hash} = block ->
      %{block | hash: Util.bin_to_string(hash)}
    end)
  end

  # Query helpers
  defp base_query() do
    from(block in Block,
      left_join: txn in Transaction,
      on: block.height == txn.block_height,
      group_by: [block.id, block.time, block.hash],
      order_by: [desc: block.height],
      select: %{
        hash: block.hash,
        height: block.height,
        time: block.time,
        txns: count(txn.id)
      }
    )
  end

  defp maybe_filter(query, %{"before" => before, "limit" => limit0} = _params) do
    limit = min(@max_limit, String.to_integer(limit0))

    query
    |> where([block], block.height < ^before)
    |> limit(^limit)
  end

  defp maybe_filter(query, %{"before" => before} = _params) do
    query
    |> where([block], block.height < ^before)
    |> limit(@default_limit)
  end

  defp maybe_filter(query, %{"limit" => limit0} = _params) do
    limit = min(@max_limit, String.to_integer(limit0))

    query
    |> limit(^limit)
  end

  defp maybe_filter(query, %{}) do
    query
    |> limit(@default_limit)
  end
end
