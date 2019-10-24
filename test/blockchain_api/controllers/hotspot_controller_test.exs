defmodule BlockchainAPIWeb.HotspotControllerTest do
  use BlockchainAPIWeb.ConnCase

  alias BlockchainAPI.Util

  describe "stats/2" do
    test "returns hotspot stats", %{conn: conn} do
      hotspot = insert(:hotspot)

      %{"data" => stats} =
        conn
        |> get(Routes.hotspot_hotspot_stats_path(conn, :stats, Util.bin_to_string(hotspot.address)))
        |> json_response(200)

      assert stats ==
      %{
        "challenges_completed" => %{
            "24h" => 0,
            "30d" => 0,
            "7d" => 0,
            "all_time" => 0
        },
        "challenges_witnessed" => %{
          "24h" => 0,
          "30d" => 0,
          "7d" => 0,
          "all_time" => 0
        },
        "consensus_groups" => %{
          "24h" => 0,
          "30d" => 0,
          "7d" => 0,
          "all_time" => 0
        },
        "earning_percentile" => %{
          "24h" => 0,
          "30d" => 0,
          "7d" => 0,
          "all_time" => 0
        },
        "furthest_witness" => nil,
        "furthest_witness_percentile" => 0,
        "hlm_earned" => %{
          "24h" => 0,
          "30d" => 0,
          "7d" => 0,
          "all_time" => 0
        },
        "witnessed_percentile" => %{
          "24h" => 0,
          "30d" => 0,
          "7d" => 0,
          "all_time" => 0
        }
      }
    end
  end
end
