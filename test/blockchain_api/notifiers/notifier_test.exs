defmodule BlockchainAPI.NotifierTest do
  use BlockchainAPI.DataCase

  alias BlockchainAPI.{
    Notifier,
    Query
  }

  describe "add_hotspot_failed/2" do
    setup [:insert_account, :insert_hotspot, :insert_pending_gateway]

    test "sends notification when hotspot already exists", %{pending_gateway: pg} do
      resp = Notifier.add_hotspot_failed(:already_exists, pg)
      assert :ok == resp
    end

    test "sends notification when hotspot times out" do
      pg = insert_pending_gateway(%{hotspot: %{address: :crypto.strong_rand_bytes(32), owner: :crypto.strong_rand_bytes(32)}})
      resp = Notifier.add_hotspot_failed(:timed_out, pg)
      assert :ok == resp
    end
  end

  describe "confirm_location_failed/2" do
    setup [:insert_account, :insert_hotspot, :insert_pending_location]

    test "sends notification when confirm location fails", %{pending_location: pl} do
      resp = Notifier.confirm_location_failed(pl)
      assert :ok == resp
    end
  end

  defp insert_account(_) do
    {:ok, account} =
      Query.Account.create(%{
        name: "Jane Doe",
        balance: 4,
        address: :crypto.strong_rand_bytes(32),
        fee: 1,
        nonce: 2
      })
    {:ok, %{account: account}}
  end

  defp insert_hotspot(%{account: account}) do
    {:ok, hotspot} =
      Query.Hotspot.create(%{
        address: :crypto.strong_rand_bytes(32),
        owner: account.address,
        location: "loc1",
        long_street: "long street",
        long_city: "San Francisco",
        long_state: "California",
        long_country: "United States",
        short_street: "ls",
        short_city: "SF",
        short_state: "CA",
        short_country: "US",
        score: 2,
        score_update_height: 4
      })
    {:ok, %{hotspot: hotspot}}
  end

  defp insert_pending_gateway(%{hotspot: hotspot}) do
    pg =
      Query.PendingGateway.create(%{
        hash: :crypto.strong_rand_bytes(32),
        status: "pending",
        gateway: hotspot.address,
        owner: hotspot.owner,
        fee: 1,
        staking_fee: 1,
        txn: "fake_txn",
        submit_height: 4
      })
    {:ok, %{pending_gateway: pg}}
  end

  defp insert_pending_location(%{hotspot: hotspot}) do
    pl =
      Query.PendingLocation.create(%{
        status: "pending",
        location: "location1",
        fee: 1,
        staking_fee: 1,
        nonce: 1,
        gateway: hotspot.address,
        hash: :crypto.strong_rand_bytes(32),
        txn: "txn1",
        submit_height: 1,
        owner: hotspot.owner
      })
    {:ok, %{pending_location: pl}}
  end
end
