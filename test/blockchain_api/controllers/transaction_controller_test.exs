defmodule BlockchainAPIWeb.TransactionControllerTest do
  use BlockchainAPIWeb.ConnCase

  alias BlockchainAPI.{
    Query,
    Util
  }

  describe "index/2" do
    setup [:insert_election_transactions]

    test "returns election transactions with consensus members", %{conn: conn, member: member} do
      BlockchainAPI.Repo.all(BlockchainAPI.Schema.ConsensusMember)
      %{"data" => [%{"members" => [member_address]}]} =
        conn
        |> get(Routes.transaction_path(conn, :index, %{}))
        |> json_response(200)

      assert member_address == Util.bin_to_string(member.address)
    end

    test "returns election transaction consensus members for a given block", %{conn: conn, member: member, block: b} do
      BlockchainAPI.Repo.all(BlockchainAPI.Schema.ConsensusMember)
      %{"data" => [%{"members" => [member_address]}]} =
        conn
        |> get(Routes.transaction_path(conn, :index, %{"block_height" => b.height}))
        |> json_response(200)

      assert member_address == Util.bin_to_string(member.address)
    end
  end

  defp insert_election_transactions(_) do
    {:ok, b} =
      Query.Block.create(%{
        hash: "hash1",
        height: 1,
        round: 1,
        time: 1
      })
    {:ok, t} =
      Query.Transaction.create(b.height, %{
        hash: "hash2",
        type: "election"
      })
    {:ok, et} =
      Query.ElectionTransaction.create(%{
        hash: t.hash,
        proof: "proof1",
        delay: 1,
        election_height: b.height
      })
    {:ok, cm} =
      Query.ConsensusMember.create(%{
        address: "address1",
        election_transactions_id: et.id
      })
    {:ok, member: cm, block: b}
  end
end
