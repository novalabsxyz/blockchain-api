defmodule BlockchainAPIWeb.TransactionControllerTest do
  use BlockchainAPIWeb.ConnCase

  alias BlockchainAPI.{
    Query,
    Util
  }

  describe "index/2" do
    setup [:insert_election_transactions]

    test "returns election transaction consensus members for a given block", %{conn: conn, members: [member1, member2], block: b} do
      BlockchainAPI.Repo.all(BlockchainAPI.Schema.ConsensusMember)
      %{"data" => [%{"members" => member_addresses}]} =
        conn
        |> get(Routes.transaction_path(conn, :index, %{"block_height" => b.height}))
        |> json_response(200)

      [address1, address2] = Enum.sort(member_addresses)

      assert address1 == Util.bin_to_string(member1.address)
      assert address2 == Util.bin_to_string(member2.address)
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
    {:ok, cm1} =
      Query.ConsensusMember.create(%{
        address: "address1",
        election_transactions_id: et.id
      })
    {:ok, cm2} =
      Query.ConsensusMember.create(%{
        address: "address2",
        election_transactions_id: et.id
      })
    {:ok, members: [cm1, cm2], block: b}
  end
end
