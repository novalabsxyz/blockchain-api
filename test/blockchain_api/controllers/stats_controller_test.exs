defmodule BlockchainAPIWeb.StatsControllerTest do
  use BlockchainAPIWeb.ConnCase
  alias BlockchainAPI.Query
  import BlockchainAPI.TestHelpers

  describe "StatsController" do
    setup do
      account_fixture(%{balance: 2, address: "account1"})
      account_fixture(%{balance: 5, address: "account2"})

      :ok
    end

    test "stats index/2 returns supply stats" do
      %{"data" => %{"token_supply" => %{"total" => total_supply}}} =
        build_conn
        |> get(Routes.stats_path(conn, :show, %{}))
        |> json_response(200)

      assert total_supply == 7
    end
  end
end
