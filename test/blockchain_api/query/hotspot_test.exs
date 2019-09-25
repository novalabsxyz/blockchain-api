defmodule BlockchainAPI.Query.HotspotTest do
  use BlockchainAPI.DataCase

  alias BlockchainAPI.{
    Query,
    Util
  }

  describe "stats/1" do
    test "it returns challenges_completed" do
      hotspot_address =
        insert(:poc_receipt)
        |> Map.get(:gateway)
        |> Util.bin_to_string()

      %{challenges_completed: challenges_completed} = Query.Hotspot.stats(hotspot_address)

      assert challenges_completed == %{
        "24h" => 1,
        "7d" => 1,
        "30d" => 1,
        "all_time" => 1
      }
    end

    test "it returns consensus groups" do
      hotspot_address =
        insert(:consensus_member)
        |> Map.get(:address)
        |> Util.bin_to_string()

      %{consensus_groups: consensus_groups} = Query.Hotspot.stats(hotspot_address)

      assert consensus_groups == %{
        "24h" => 1,
        "7d" => 1,
        "30d" => 1,
        "all_time" => 1
      }
    end

    test "it returns hlm earned" do
      rt0 = insert(:reward_txn)
      rt1 = insert(:reward_txn, gateway: rt0.gateway)
      rt2 = insert(:reward_txn, gateway: rt0.gateway)

      rewards_total = (rt0.amount + rt1.amount + rt2.amount) |> Decimal.new()

      %{hlm_earned: hlm_earned} = Query.Hotspot.stats(Util.bin_to_string(rt0.gateway))

      assert hlm_earned == %{
        "24h" => rewards_total,
        "7d" => rewards_total,
        "30d" => rewards_total,
        "all_time" => rewards_total
      }
    end

    test "it returns earning_percentile" do
      rt_a = insert(:reward_txn, amount: 1)
      rt_b = insert(:reward_txn, amount: 2)
      rt_c = insert(:reward_txn, amount: 3)
      rt_d = insert(:reward_txn, amount: 4)

      %{earning_percentile: earning_percentile_a} = Query.Hotspot.stats(Util.bin_to_string(rt_a.gateway))
      %{earning_percentile: earning_percentile_b} = Query.Hotspot.stats(Util.bin_to_string(rt_b.gateway))
      %{earning_percentile: earning_percentile_c} = Query.Hotspot.stats(Util.bin_to_string(rt_c.gateway))
      %{earning_percentile: earning_percentile_d} = Query.Hotspot.stats(Util.bin_to_string(rt_d.gateway))

      assert earning_percentile_a == %{
        "24h" => 0,
        "7d" => 0,
        "30d" => 0,
        "all_time" => 0
      }

      assert earning_percentile_b == %{
        "24h" => 33,
        "7d" => 33,
        "30d" => 33,
        "all_time" => 33
      }

      assert earning_percentile_c == %{
        "24h" => 67,
        "7d" => 67,
        "30d" => 67,
        "all_time" => 67
      }

      assert earning_percentile_d == %{
        "24h" => 100,
        "7d" => 100,
        "30d" => 100,
        "all_time" => 100
      }
    end

    test "it returns challenges witnessed" do
      hotspot_address =
        insert(:poc_witness)
        |> Map.get(:gateway)
        |> Util.bin_to_string()

      %{challenges_witnessed: challenges_witnessed} = Query.Hotspot.stats(hotspot_address)

      assert challenges_witnessed == %{
        "24h" => 1,
        "7d" => 1,
        "30d" => 1,
        "all_time" => 1
      }
    end

    test "it returns witnessed percentile" do
      # Each insert creates a new hotspot (8), but only 3 are associated with a poc witness

      pocw_a = insert(:poc_witness)

      pocw_b = insert(:poc_witness)
      pe_b = insert(:poc_path_element, challengee: pocw_b.gateway, challengee_owner: pocw_b.owner, challengee_loc: pocw_b.location)
      insert(:poc_witness, poc_path_elements_id: pe_b.id, gateway: pe_b.challengee, owner: pe_b.challengee_owner, location: pe_b.challengee_loc)

      pocw_c = insert(:poc_witness)
      pe_c = insert(:poc_path_element, challengee: pocw_c.gateway, challengee_owner: pocw_c.owner, challengee_loc: pocw_c.location)
      insert(:poc_witness, poc_path_elements_id: pe_c.id, gateway: pe_c.challengee, owner: pe_c.challengee_owner, location: pe_c.challengee_loc)
      insert(:poc_witness, poc_path_elements_id: pe_c.id, gateway: pe_c.challengee, owner: pe_c.challengee_owner, location: pe_c.challengee_loc)

      %{witnessed_percentile: witnessed_percentile_a} = Query.Hotspot.stats(Util.bin_to_string(pocw_a.gateway))
      %{witnessed_percentile: witnessed_percentile_b} = Query.Hotspot.stats(Util.bin_to_string(pocw_b.gateway))
      %{witnessed_percentile: witnessed_percentile_c} = Query.Hotspot.stats(Util.bin_to_string(pocw_c.gateway))

      assert witnessed_percentile_a == %{
        "24h" => 71,
        "7d" => 71,
        "30d" => 71,
        "all_time" => 71
      }

      assert witnessed_percentile_b == %{
        "24h" => 86,
        "7d" => 86,
        "30d" => 86,
        "all_time" => 86
      }

      assert witnessed_percentile_c == %{
        "24h" => 100,
        "7d" => 100,
        "30d" => 100,
        "all_time" => 100
      }
    end

    test "it returns furthest witness" do
      pocw = insert(:poc_witness, distance: 5)
      pe = insert(:poc_path_element, challengee: pocw.gateway, challengee_owner: pocw.owner, challengee_loc: pocw.location)
      insert(:poc_witness, distance: 10, poc_path_elements_id: pe.id, gateway: pe.challengee, owner: pe.challengee_owner, location: pe.challengee_loc)

      %{furthest_witness: furthest_witness} = Query.Hotspot.stats(Util.bin_to_string(pocw.gateway))

      assert furthest_witness == 10
    end

    test "it returns furthest witness percentile" do
      pocw_a = insert(:poc_witness, distance: 10)
      pocw_b = insert(:poc_witness, distance: 30)
      pocw_c = insert(:poc_witness, distance: 20)

      %{furthest_witness_percentile: furthest_witness_percentile_a} = Query.Hotspot.stats(Util.bin_to_string(pocw_a.gateway))
      %{furthest_witness_percentile: furthest_witness_percentile_b} = Query.Hotspot.stats(Util.bin_to_string(pocw_b.gateway))
      %{furthest_witness_percentile: furthest_witness_percentile_c} = Query.Hotspot.stats(Util.bin_to_string(pocw_c.gateway))

      assert furthest_witness_percentile_a == 0
      assert furthest_witness_percentile_b == 100
      assert furthest_witness_percentile_c == 50
    end
  end
end
