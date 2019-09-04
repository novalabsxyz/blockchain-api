defmodule BlockchainAPIWeb.ElectionTransactionControllerTest do
  use BlockchainAPIWeb.ConnCase

  alias BlockchainAPI.{
    Query,
    Repo,
    Schema.ElectionTransaction
  }

  describe "index/2" do
    setup [:insert_election_transactions]

    test "returns list of conensus groups", %{conn: conn} do
      %{"data" => [current_group|_] = groups} =
        conn
        |> get(Routes.groups_path(conn, :index, %{}))
        |> json_response(200)

      oldest_group = List.last(groups)
      assert length(groups) == 10
      assert %{
        "members" => [
          %{"address" => _, "score" => _},
          %{"address" => _, "score" => _},
          %{"address" => _, "score" => _}
        ],
        "block" => %{"hash" => _, "height" => _, "round" => _, "time" => _},
        "id" => _,
        "start_time" => _,
        "hash" => _
      } = oldest_group
    end

    test "returns n consensus groups when limit param is set", %{conn: conn} do
      %{"data" => [group|_] = groups} =
        conn
        |> get(Routes.groups_path(conn, :index, %{limit: 4}))
        |> json_response(200)

      assert length(groups) == 4
    end

    test "returns prior consensus groups when before param is set", %{conn: conn} do
      first_id =
        ElectionTransaction
        |> Repo.all()
        |> hd()
        |> Map.get(:id)

      %{"data" =>  groups} =
        conn
        |> get(Routes.groups_path(conn, :index, %{before: first_id + 1}))
        |> json_response(200)

      assert length(groups) == 1
    end
  end

  defp insert_election_transactions(_) do
    Enum.each(1..10, fn n ->
      x = 3 * n - 2
      y = 3 * n - 1
      z = 3 * n
      {:ok, b1} =
        Query.Block.create(%{
          hash: :crypto.strong_rand_bytes(32),
          height: x,
          round: x,
          time: x
        })
      {:ok, t1} =
        Query.Transaction.create(b1.height, %{
          hash: :crypto.strong_rand_bytes(32),
          type: "election"
        })
      {:ok, et} =
        Query.ElectionTransaction.create(%{
          hash: t1.hash,
          proof: "proof#{x}",
          delay: 1,
          election_height: b1.height
        })
      {:ok, cm1} =
        Query.ConsensusMember.create(%{
          address: "address#{x}",
          election_transactions_id: et.id
        })
      {:ok, cm2} =
        Query.ConsensusMember.create(%{
          address: "address#{y}",
          election_transactions_id: et.id
        })
      {:ok, cm3} =
        Query.ConsensusMember.create(%{
          address: "address#{z}",
          election_transactions_id: et.id
        })
      {:ok, b2} =
        Query.Block.create(%{
          hash: :crypto.strong_rand_bytes(32),
          height: y,
          round: y,
          time: y
        })
      {:ok, _t2} =
        Query.Transaction.create(b2.height, %{
          hash: :crypto.strong_rand_bytes(32),
          type: "location"
        })
      {:ok, b3} =
        Query.Block.create(%{
          hash: :crypto.strong_rand_bytes(32),
          height: z,
          round: z,
          time: z
        })
      {:ok, _t3} =
        Query.Transaction.create(b3.height, %{
          hash: :crypto.strong_rand_bytes(32),
          type: "payment"
        })
      {:ok, members: [cm1, cm2, cm3], blocks: [b1, b2, b3], group: et}
    end)
  end
end
