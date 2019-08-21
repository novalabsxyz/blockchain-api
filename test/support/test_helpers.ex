defmodule BlockchainAPI.TestHelpers do
  alias BlockchainAPI.{Query, Util}

  @num_challenges 1000

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

  def insert_hotspot_activity do
    fake_location = Util.h3_to_string(631210983218633727)
    {:ok, account} = Query.Account.create(%{
      name: "Jane Doe",
      balance: 100,
      address: :crypto.strong_rand_bytes(32),
      fee: 0,
      nonce: 0
    })
    hotspot_map =
      %{
        address: :crypto.strong_rand_bytes(32),
        owner: account.address,
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
    {:ok, hotspot} = Query.Hotspot.create(hotspot_map)
    Range.new(1, 10)
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
            gateway: to_string(h),
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
        if rem(h, 2) == 1 do
          {:ok, pe} = Query.POCPathElement.create(%{
            poc_receipts_transactions_hash: c.hash,
            challengee_owner: account.address,
            challengee: hotspot.address,
            challengee_loc: "fakelocation",
            result: "untested"
          })
          {:ok,  pocw} = Query.POCWitness.create(%{
            poc_path_elements_id: pe.id,
            gateway: g.gateway,
            owner: account.address,
            location: "8c283082a18b3ff",
            timestamp: b.time,
            signal: 10,
            packet_hash: "hash10",
            signature: "signature10"
          })
          {:ok, pocr} = Query.POCReceipt.create(%{
            poc_path_elements_id: pe.id,
            gateway:  g.gateway,
            owner: account.address,
            location: "7b173082a18b3gg",
            timestamp: b.time,
            signal: 11,
            data: "foo",
            signature: "signature11",
            origin: "p2p"
          })
          Query.HotspotActivity.create(%{
            gateway: g.gateway,
            poc_witness_id: pocw.id,
            poc_witness_challenge_id: c.id,
            poc_score: 19,
            poc_score_delta: 2
          })
          Query.HotspotActivity.create(%{
            gateway: g.gateway,
            poc_rx_txn_block_height: b.height,
            poc_rx_txn_block_time: b.time,
            poc_rx_id: pocr.id,
            poc_rx_challenge_id: c.id,
            poc_score: 23,
            poc_score_delta: 4
          })
        else
          Query.HotspotActivity.create(%{
            gateway: g.gateway |> String.to_integer() |> Kernel.-(1) |> to_string(),
            reward_type: "poc_witnesses",
            reward_amount: 10,
            reward_block_height: b.height,
            reward_block_time: b.time
          })
          Query.HotspotActivity.create(%{
            gateway: g.gateway |> String.to_integer() |> Kernel.-(1) |> to_string(),
            reward_type: "poc_challengers",
            reward_amount: 15,
            reward_block_height: b.height,
            reward_block_time: b.time
          })
        end
        c
      end)
  end
end
