defmodule BlockchainAPIWeb.HotspotControllerTest do
  use BlockchainAPIWeb.ConnCase

  alias BlockchainAPI.{
    Query,
    Util
  }

  describe "show/2" do
    setup [:insert_account]

    test "returns empty map when account doesn't have a hotspot", %{conn: conn, account: account} do
      %{"data" => data} =
        conn
        |> get(Routes.hotspot_path(conn, :show, Util.bin_to_string(account.address)))
        |> json_response(200)

      assert data == %{}
    end
  end

  defp insert_account(_) do
    {:ok, account} = Query.Account.create(%{name: "Test Acc", balance: 0, address: :crypto.strong_rand_bytes(32), fee: 1, nonce: 0})
    {:ok, %{account: account}}
  end
end
