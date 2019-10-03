defmodule BlockchainAPI.Cache.HotspotStats do
  use GenServer

  alias BlockchainAPI.Query.HotspotStats

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def update_cache do
    GenServer.cast(__MODULE__, :update_cache)
  end

  def init(_) do
    cache = :ets.new(:hotspot_stats, [:named_table])
    insert_stats(cache)
    {:ok, %{cache: cache}}
  end

  def handle_cast(:update_cache, %{cache: cache} = state) do
    insert_stats(cache)
    {:ok, state}
  end

  defp insert_stats(cache) do
    insert_challenges_completed(cache)
    insert_consensus_groups(cache)
    insert_hlm_earned(cache)
    insert_earning_percentile(cache)
    insert_challenges_witnessed(cache)
    insert_witnessed_percentile(cache)
    insert_furthest_witness(cache)
    insert_furthest_witness_percentile(cache)
  end

  defp insert_challenges_completed(cache) do
    HotspotStats.challenges_completed() 
    |> set_cache(cache, :challenges_completed)
  end

  defp insert_consensus_groups_cache(cache) do
    HotspotStats.consensus_groups() 
    |> set_cache(cache, :consensus_groups)
  end

  defp insert_hlm_earned_cache(cache) do
    HotspotStats.hlm_earned() 
    |> set_cache(cache, :hlm_earned)
  end

  defp insert_earning_percentile(cache) do
    HotspotStats.earning_percentiles()
    |> set_cache(cache, :earning_percentile)
  end

  defp insert_challenges_witnessed(cache) do
    HotspotStats.challenges_witnessed() 
    |> set_cache(cache, :challenges_witnessed)
  end

  defp insert_witnessed_percentile(cache) do
    HotspotStats.witnessed_percentiles()
    |> set_cache(cache, :witnessed_percentile)
  end

  defp insert_furthest_witness(cache) do
    HotspotStats.furthest_witnesses()
    |> set_cache(cache, :furthest_witness)
  end

  defp insert_furthest_witness_percentile(cache) do
    HotspotStats.furthest_witness_percentiles()
    |> set_cache(cache, :furthest_witness_percentile)
  end

  defp set_cache(map, cache, stat) do
    Enum.each(map, fn {time, entries} ->
      Enum.each(entries, fn {address, value} ->
        :ets.insert(cache, {address, stat, time}, value)
      end)
    end)
  end
end
