defmodule BlockchainAPIWeb.StatsControllerTest do
  use BlockchainAPIWeb.ConnCase
  alias BlockchainAPI.{Query, Util}
  import BlockchainAPI.TestHelpers

  describe "StatsController" do
    setup do
      account_fixture(%{balance: 2, address: "account1"})
      account_fixture(%{balance: 5, address: "account2"})

      block_fixture(%{time: Util.shifted_unix_time(hours: -21), height: 6})
      block_fixture(%{time: Util.shifted_unix_time(hours: -22), height: 5})
      block_fixture(%{time: Util.shifted_unix_time(hours: -26), height: 4})
      block_fixture(%{time: Util.shifted_unix_time(hours: -28), height: 3})
      block_fixture(%{time: Util.shifted_unix_time(hours: -31), height: 2})
      block_fixture(%{time: Util.shifted_unix_time(hours: -45), height: 1})

      :ok
    end

    test "stats index/2 returns supply stats" do
      %{"data" => %{"token_supply" => %{"total" => total_supply}}} =
        build_conn
        |> get(Routes.stats_path(conn, :show, %{}))
        |> json_response(200)

      assert total_supply == 7
    end

    test "stats index/2 returns block time stats" do
      %{
        "data" => %{
          "block_time" => %{
            "24h" => day_block_time,
            "7d" => week_block_time,
            "30d" => month_block_time
          }
        }
      } =
        build_conn
        |> get(Routes.stats_path(conn, :show, %{}))
        |> json_response(200)

      assert day_block_time == 9000.0
      assert week_block_time == 17280.0
      assert month_block_time == 17280.0
    end
  end
end
