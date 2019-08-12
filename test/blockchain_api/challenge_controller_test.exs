defmodule BlockchainAPIWeb.ChallengeControllerTest do
  use BlockchainAPIWeb.ConnCase
  alias BlockchainAPI.{Query, Util}

  @num_challenges 1000
  @default_limit 100
  @max_limit 500

  describe "test challenge controller" do
    setup do
      challenges = insert_fake_challenges()
      case length(challenges) == @num_challenges do
        true -> :ok
        false -> :error
      end
    end

    test "challenge index/2 returns #{@default_limit} challenges with no limit", %{conn: conn} do
      %{"data" => challenges} = conn
                                |> get(Routes.challenge_path(conn, :index, %{}))
                                |> json_response(200)

      assert length(challenges) == @default_limit
    end

    test "challenge index/2 returns #{@max_limit} challenges when limit > #{@max_limit}", %{conn: conn} do
      %{"data" => challenges} = conn
                                |> get(Routes.challenge_path(conn, :index, %{"limit" => 1000}))
                                |> json_response(200)

      assert length(challenges) == @max_limit
    end

    test "challenge index/2 before without limit", %{conn: conn} do
      last_poc_id = Query.POCReceiptsTransaction.last_poc_id()

      %{"data" => challenges} = conn
                                |> get(Routes.challenge_path(conn, :index, %{"before" => last_poc_id}))
                                |> json_response(200)

      assert length(challenges) == @default_limit
    end

    test "challenge index/2 with valid limit", %{conn: conn} do
      %{"data" => challenges} = conn
                                |> get(Routes.challenge_path(conn, :index, %{"limit" => 400}))
                                |> json_response(200)

      assert length(challenges) == 400
    end

    test "challenge index/2 before with invalid limit", %{conn: conn} do
      last_poc_id = Query.POCReceiptsTransaction.last_poc_id()

      %{"data" => challenges} = conn
                                |> get(Routes.challenge_path(conn, :index, %{"before" => last_poc_id, "limit" => 600}))
                                |> json_response(200)


      assert length(challenges) == @max_limit
    end

    def insert_fake_challenges() do
      fake_location = Util.h3_to_string(631210983218633727)
      hotspot_map =
        %{
          address: :crypto.strong_rand_bytes(32),
          owner: :crypto.strong_rand_bytes(32),
          location: fake_location,
          long_city: "San Rafael",
          long_country: "United States",
          long_state: "California",
          long_street: "Las Colindas Road",
          short_city: "San Rafael",
          short_country: "US",
          short_state: "CA",
          short_street: "Las Colindas Rd"
        }
      {:ok, _fake_spot} = Query.Hotspot.create(hotspot_map)
      Range.new(1, @num_challenges)
      |> Enum.map(
        fn(h) ->
          block_map = %{hash: :crypto.strong_rand_bytes(32), height: h, round: h, time: h}
          {:ok, b} = Query.Block.create(block_map)
          txn_map =
            %{
              hash: :crypto.strong_rand_bytes(32),
              type: "doesnt_matter"
            }
          {:ok, t} = Query.Transaction.create(b.height, txn_map)
          gw_map =
            %{
              owner: :crypto.strong_rand_bytes(32),
              gateway: :crypto.strong_rand_bytes(32),
              fee: 0,
              staking_fee: 0,
              hash: t.hash
            }
          {:ok, g} = Query.GatewayTransaction.create(gw_map)
          request_map =
            %{hash: t.hash,
              signature: :crypto.strong_rand_bytes(32),
              onion: :crypto.strong_rand_bytes(32),
              owner: :crypto.strong_rand_bytes(32),
              challenger: g.gateway,
              location: fake_location,
              fee: 0
            }
          {:ok, r} = Query.POCRequestTransaction.create(request_map)
          challenge_map =
            %{hash: r.hash,
              signature: :crypto.strong_rand_bytes(32),
              onion: :crypto.strong_rand_bytes(32),
              challenger_owner: r.owner,
              challenger: r.challenger,
              challenger_loc: fake_location,
              poc_request_transactions_id: r.id,
              fee: 0
            }
          {:ok, c} = Query.POCReceiptsTransaction.create(challenge_map)
          c
        end)
    end
  end
end

