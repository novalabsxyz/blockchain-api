defmodule BlockchainAPIWeb.ElectionTransactionControllerTest do
  use BlockchainAPIWeb.ConnCase

  import Ecto.Query

  alias BlockchainAPI.{
    Query,
    Repo,
    Schema.ElectionTransaction,
    Util
  }

  describe "index/2" do
    setup [:insert_election_transactions]

    test "returns list of conensus elections", %{conn: conn} do
      %{"data" => elections} =
        conn
        |> get(Routes.election_transaction_path(conn, :index, %{}))
        |> json_response(200)

      oldest_election = List.last(elections)
      assert length(elections) == 10
      assert %{
               "delay" => _,
               "id" => _,
               "election_height" => _,
               "start_height" => _,
               "start_time" => _,
               "hash" => _
             } = oldest_election
    end

    test "returns n consensus elections when limit param is set", %{conn: conn} do
      %{"data" => elections} =
        conn
        |> get(Routes.election_transaction_path(conn, :index, %{limit: 4}))
        |> json_response(200)

      assert length(elections) == 4
    end

    test "returns prior consensus elections when before param is set", %{conn: conn} do
      first_id =
        ElectionTransaction
        |> Repo.replica.all()
        |> hd()
        |> Map.get(:id)

      %{"data" => elections} =
        conn
        |> get(Routes.election_transaction_path(conn, :index, %{before: first_id + 1}))
        |> json_response(200)

      assert length(elections) == 1
    end

    test "returns elections when last block is an election block", %{conn: conn} do
      insert_election(31)
      %{"data" => elections} =
        conn
        |> get(Routes.election_transaction_path(conn, :index))
        |> json_response(200)
    end
  end

  describe "show/2" do
    setup [:insert_election_transactions]

    test "returns election transaction by hash", %{conn: conn} do
      etxn =
        from(
          e in ElectionTransaction,
          limit: 1
        )
        |> Repo.replica.one()

      %{"data" => resp} =
        conn
        |> get(Routes.election_transaction_path(conn, :show, Util.bin_to_string(etxn.hash)))
        |> json_response(200)

      assert %{
               "delay" => _,
               "election_height" => _,
               "start_height" => _,
               "hash" => _,
               "start_time" => _,
               "end_time" => _,
               "blocks_count" => _,
               "members" => [_, _, _]
             } = resp
    end

    test "returns last election transaction", %{conn: conn} do
      etxn =
        from(
          e in ElectionTransaction,
          order_by: [desc: :id],
          limit: 1
        )
        |> Repo.replica.one()

      %{"data" => resp} =
        conn
        |> get(Routes.election_transaction_path(conn, :show, Util.bin_to_string(etxn.hash)))
        |> json_response(200)

      assert %{
               "delay" => _,
               "election_height" => _,
               "start_height" => _,
               "hash" => _,
               "start_time" => _,
               "end_time" => _,
               "blocks_count" => _,
               "members" => [_, _, _]
             } = resp
    end
test "returns empty map when no election transaction matches hash", %{conn: conn} do
      fake_hash = :crypto.strong_rand_bytes(32) |> Util.bin_to_string()

      %{"data" => resp} =
        conn
        |> get(Routes.election_transaction_path(conn, :show, fake_hash))
        |> json_response(200)

      assert resp == %{}
    end

    test "returns last election when it is in last block", %{conn: conn} do
      {:ok, election_transaction} = insert_election(31)

      %{"data" => resp} =
        conn
        |> get(Routes.election_transaction_path(conn, :show, Util.bin_to_string(election_transaction.hash)))
        |> json_response(200)
    end
  end

  defp insert_election_transactions(_) do
    Enum.each(1..10, fn n ->
      x = 3 * n - 2
      y = 3 * n - 1
      z = 3 * n

      insert_election(x)

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
    end)
  end

  defp insert_election(n) do
    {:ok, b1} =
      Query.Block.create(%{
        hash: :crypto.strong_rand_bytes(32),
        height: n,
        round: n,
        time: n
      })

    {:ok, t1} =
      Query.Transaction.create(b1.height, %{
        hash: :crypto.strong_rand_bytes(32),
        type: "election"
      })

    {:ok, et} =
      Query.ElectionTransaction.create(%{
        hash: t1.hash,
        proof: "proof#{n}",
        delay: 1,
        election_height: b1.height
      })

    {:ok, _cm1} =
      Query.ConsensusMember.create(%{
        address: "address#{n}",
        election_transactions_id: et.id
      })

    {:ok, _cm2} =
      Query.ConsensusMember.create(%{
        address: "address#{n+1}",
        election_transactions_id: et.id
      })

    {:ok, _cm3} =
      Query.ConsensusMember.create(%{
        address: "address#{n+2}",
        election_transactions_id: et.id
      })
    {:ok, et}
  end
end
