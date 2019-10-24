defmodule BlockchainAPI.Factory do
  use ExMachina.Ecto, repo: BlockchainAPI.Repo

  alias BlockchainAPI.{
    Schema.Account,
    Schema.Block,
    Schema.ConsensusMember,
    Schema.ElectionTransaction,
    Schema.GatewayTransaction,
    Schema.Hotspot,
    Schema.POCPathElement,
    Schema.POCReceipt,
    Schema.POCReceiptsTransaction,
    Schema.POCRequestTransaction,
    Schema.POCWitness,
    Schema.RewardsTransaction,
    Schema.RewardTxn,
    Schema.Transaction,
    Util
  }

  def block_factory do
    %Block{
      hash: :crypto.strong_rand_bytes(32),
      round: sequence(:block, & &1),
      time: sequence(:time, & "#{Util.current_time() + &1}"),
      height: sequence(:block, & &1),
    }
  end

  def account_factory do
    %Account{
      balance: Enum.random(1..100_000_000),
      address: :crypto.strong_rand_bytes(32),
      fee: Enum.random(1..100),
      nonce: sequence(:account, & &1)
    }
  end

  def hotspot_factory do
    %Hotspot{
      address: :crypto.strong_rand_bytes(32),
      owner: insert(:account).address,
      location: Util.h3_to_string(631_210_983_218_633_727),
      long_street: "Federal St",
      long_city: "San Francisco",
      long_state: "California",
      long_country: "United States",
      short_street: "Federal St",
      short_city: "SF",
      short_state: "CA",
      short_country: "US",
      score: :rand.uniform() * 100,
      score_update_height: Enum.random(1..10)
    }
  end

  def transaction_factory do
    %Transaction{
      type: Enum.random(
        ["gateway", "security", "data_credit", "election", "poc_request",
          "poc_receipts", "rewards", "payment", "location"
        ]),
      block_height: insert(:block).height,
      hash: :crypto.strong_rand_bytes(32),
      status: "cleared"
    }
  end

  def gateway_transaction_factory do
    %GatewayTransaction{
      hash: insert(:transaction).hash,
      status: "cleared",
      gateway: :crypto.strong_rand_bytes(32),
      owner: :crypto.strong_rand_bytes(32),
      payer: :crypto.strong_rand_bytes(32),
      fee: 0,
      staking_fee: 0
    }
  end

  def election_transaction_factory do
    %ElectionTransaction{
      hash: insert(:transaction).hash,
      proof: :crypto.strong_rand_bytes(32),
      delay: Enum.random(1..50),
      election_height: sequence(:election_height, & &1),
    }
  end

  def poc_request_transaction_factory do
    %POCRequestTransaction{
      challenger: insert(:gateway_transaction).gateway,
      location: Util.h3_to_string(631_210_983_218_633_727),
      hash: insert(:transaction).hash,
      signature: :crypto.strong_rand_bytes(32),
      fee: Enum.random(1..100),
      onion: :crypto.strong_rand_bytes(32),
      owner: insert(:account).address
    }
  end

  def poc_receipts_transaction_factory do
    req_txn =insert(:poc_request_transaction)
    %POCReceiptsTransaction{
      poc_request_transactions_id: req_txn.id,
      challenger: req_txn.challenger,
      challenger_owner: req_txn.owner,
      challenger_loc: req_txn.location,
      hash: req_txn.hash,
      signature: :crypto.strong_rand_bytes(32),
      fee: Enum.random(1..100),
      onion: :crypto.strong_rand_bytes(32)
    }
  end

  def poc_path_element_transaction_factory do
    hotspot = insert(:hotspot)
    %POCPathElement{
      challengee: hotspot.address,
      challengee_loc: hotspot.location,
      challengee_owner: hotspot.owner,
      poc_receipts_transactions_hash: insert(:poc_receipts_transaction).hash,
      result: "untested"
    }
  end

  def rewards_transaction_factory do
    %RewardsTransaction{
      hash: insert(:transaction).hash,
      fee: Enum.random(1..100)
    }
  end

  def reward_txn_factory do
    %RewardTxn{
      account: insert(:account).address,
      gateway: insert(:hotspot).address,
      amount: Enum.random(1..50),
      rewards_hash: insert(:rewards_transaction).hash,
      type: Enum.random(
        ["poc_witnesses_reward", "poc_challengers_reward", "consensus_reward",
          "securities_reward", "poc_challengees_reward"
        ])
    }
  end

  def consensus_member_factory do
    %ConsensusMember{
      address: insert(:hotspot).address,
      election_transactions_id: insert(:election_transaction).id
    }
  end

  def poc_path_element_factory do
    hotspot = insert(:hotspot)
    %POCPathElement{
      challengee: hotspot.address,
      challengee_loc: hotspot.location,
      challengee_owner: hotspot.owner,
      poc_receipts_transactions_hash: insert(:poc_receipts_transaction).hash,
      result: "untested"
    }
  end

  def poc_receipt_factory do
    poc_path_element = insert(:poc_path_element)
    %POCReceipt{
      poc_path_elements_id: poc_path_element.id,
      gateway: poc_path_element.challengee,
      owner: poc_path_element.challengee_owner,
      location: poc_path_element.challengee_loc,
      timestamp: Util.current_time(),
      signal: Enum.random(1..100),
      data: :crypto.strong_rand_bytes(32),
      signature: :crypto.strong_rand_bytes(32),
      origin: Enum.random(["p2p", "random"])
    }
  end

  def poc_witness_factory do
    poc_path_element = insert(:poc_path_element)
    %POCWitness{
      poc_path_elements_id: poc_path_element.id,
      gateway: poc_path_element.challengee,
      owner: poc_path_element.challengee_owner,
      location: poc_path_element.challengee_loc,
      timestamp: Util.current_time(),
      signal: Enum.random(1..100),
      packet_hash: :crypto.strong_rand_bytes(32),
      signature: :crypto.strong_rand_bytes(32),
      distance: :rand.uniform() * 100
    }
  end
end
