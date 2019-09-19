defmodule BlockchainAPIWeb.ChallengeControllerTest do
  use BlockchainAPIWeb.ConnCase
  import BlockchainAPI.TestHelpers
  alias BlockchainAPI.Query

  @default_limit 100
  @max_limit 500

  describe "test challenge controller" do
    setup do
      _challenges = insert_fake_challenges()
      :ok
    end

    test "challenge index/2 returns #{@default_limit} challenges with no limit", %{conn: conn} do
      %{"data" => challenges} =
        conn
        |> get(Routes.challenge_path(conn, :index, %{}))
        |> json_response(200)

      assert length(challenges) == @default_limit
    end

    test "challenge index/2 returns #{@max_limit} challenges when limit > #{@max_limit}", %{
      conn: conn
    } do
      %{"data" => challenges} =
        conn
        |> get(Routes.challenge_path(conn, :index, %{"limit" => 1000}))
        |> json_response(200)

      assert length(challenges) == @max_limit
    end

    test "challenge index/2 before without limit", %{conn: conn} do
      last_poc_id = Query.POCReceiptsTransaction.last_poc_id()

      %{"data" => challenges} =
        conn
        |> get(Routes.challenge_path(conn, :index, %{"before" => last_poc_id}))
        |> json_response(200)

      assert length(challenges) == @default_limit
    end

    test "challenge index/2 with valid limit", %{conn: conn} do
      valid_limit = 99

      %{"data" => challenges} =
        conn
        |> get(Routes.challenge_path(conn, :index, %{"limit" => valid_limit}))
        |> json_response(200)

      assert length(challenges) == valid_limit
    end

    test "challenge index/2 before with invalid limit", %{conn: conn} do
      last_poc_id = Query.POCReceiptsTransaction.last_poc_id()

      %{"data" => challenges} =
        conn
        |> get(Routes.challenge_path(conn, :index, %{"before" => last_poc_id, "limit" => 600}))
        |> json_response(200)

      assert length(challenges) == @max_limit
    end
  end
end
