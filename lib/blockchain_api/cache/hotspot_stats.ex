defmodule BlockchainAPI.Cache.HotspotStats do
  use GenServer

  alias BlockchainAPI.Query.HotspotStats

  @cache :hotspot_stats

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def update_cache do
    GenServer.cast(__MODULE__, :update_cache)
  end

  def init(_) do
    cache = :ets.new(@cache, [:named_table])
    insert_stats(cache)
    {:ok, %{cache: cache}}
  end

  def handle_cast(:update_cache, %{cache: cache} = state) do
    insert_stats(cache)
    {:ok, state}
  end

  def challenges_completed(address) do
    %{
      "24h" => :ets.lookup(@cache, {address, :challenges_completed, "24h"}),
      "7d" => :ets.lookup(@cache, {address, :challenges_completed, "7d"}),
      "30d" => :ets.lookup(@cache, {address, :challenges_completed, "30d"}),
      "all_time" => :ets.lookup(@cache, {address, :challenges_completed, "all_time"})
    }
  end

  def consensus_groups(address) do
    %{
      "24h" => :ets.lookup(@cache, {address, :consensus_groups, "24h"}),
      "7d" => :ets.lookup(@cache, {address, :consensus_groups, "7d"}),
      "30d" => :ets.lookup(@cache, {address, :consensus_groups, "30d"}),
      "all_time" => :ets.lookup(@cache, {address, :consensus_groups, "all_time"})
    }
  end

  def hlm_earned(address) do
    %{
      "24h" => :ets.lookup(@cache, {address, :hlm_earned, "24h"}),
      "7d" => :ets.lookup(@cache, {address, :hlm_earned, "7d"}),
      "30d" => :ets.lookup(@cache, {address, :hlm_earned, "30d"}),
      "all_time" => :ets.lookup(@cache, {address, :hlm_earned, "all_time"})
    }
  end

  def earning_percentile(address) do
    %{
      "24h" => :ets.lookup(@cache, {address, :earning_percentile, "24h"}),
      "7d" => :ets.lookup(@cache, {address, :earning_percentile, "7d"}),
      "30d" => :ets.lookup(@cache, {address, :earning_percentile, "30d"}),
      "all_time" => :ets.lookup(@cache, {address, :earning_percentile, "all_time"})
    }
  end

  def challenges_witnessed(address) do
    %{
      "24h" => :ets.lookup(@cache, {address, :challenges_witnessed, "24h"}),
      "7d" => :ets.lookup(@cache, {address, :challenges_witnessed, "7d"}),
      "30d" => :ets.lookup(@cache, {address, :challenges_witnessed, "30d"}),
      "all_time" => :ets.lookup(@cache, {address, :challenges_witnessed, "all_time"})
    }
  end

  def witnessed_percentile(address) do
    %{
      "24h" => :ets.lookup(@cache, {address, :witnessed_percentile, "24h"}),
      "7d" => :ets.lookup(@cache, {address, :witnessed_percentile, "7d"}),
      "30d" => :ets.lookup(@cache, {address, :witnessed_percentile, "30d"}),
      "all_time" => :ets.lookup(@cache, {address, :witnessed_percentile, "all_time"})
    }
  end

  def furthest_witness(address) do
    %{
      "24h" => :ets.lookup(@cache, {address, :furthest_witness, "24h"}),
      "7d" => :ets.lookup(@cache, {address, :furthest_witness, "7d"}),
      "30d" => :ets.lookup(@cache, {address, :furthest_witness, "30d"}),
      "all_time" => :ets.lookup(@cache, {address, :furthest_witness, "all_time"})
    }
  end

  def furthest_witness_percentile(address) do
    %{
      "24h" => :ets.lookup(@cache, {address, :furthest_witness_percentile, "24h"}),
      "7d" => :ets.lookup(@cache, {address, :furthest_witness_percentile, "7d"}),
      "30d" => :ets.lookup(@cache, {address, :furthest_witness_percentile, "30d"}),
      "all_time" => :ets.lookup(@cache, {address, :furthest_witness_percentile, "all_time"})
    }
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
    HotspotStats.challenges_completed_map()
    |> set_cache(cache, :challenges_completed)
  end

  defp insert_consensus_groups(cache) do
    HotspotStats.consensus_groups_map()
    |> set_cache(cache, :consensus_groups)
  end

  defp insert_hlm_earned(cache) do
    HotspotStats.hlm_earned_map()
    |> set_cache(cache, :hlm_earned)
  end

  defp insert_earning_percentile(cache) do
    HotspotStats.earning_percentiles_map()
    |> set_cache(cache, :earning_percentile)
  end

  defp insert_challenges_witnessed(cache) do
    HotspotStats.challenges_witnessed_map()
    |> set_cache(cache, :challenges_witnessed)
  end

  defp insert_witnessed_percentile(cache) do
    HotspotStats.witnessed_percentiles_map()
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
        :ets.insert(cache, {{address, stat, time}, value})
      end)
    end)
  end
end
