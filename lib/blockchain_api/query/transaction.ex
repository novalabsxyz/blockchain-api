defmodule BlockchainAPI.Query.Transaction do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{
    Repo,
    Schema.Block,
    Schema.CoinbaseTransaction,
    Schema.DataCreditTransaction,
    Schema.ElectionTransaction,
    Schema.GatewayTransaction,
    Schema.LocationTransaction,
    Schema.PaymentTransaction,
    Schema.POCReceiptsTransaction,
    Schema.POCRequestTransaction,
    Schema.RewardsTransaction,
    Schema.SecurityTransaction,
    Schema.Transaction,
    Util
  }

  def list(_params) do
    query =
      from(transaction in Transaction,
        left_join: block in Block,
        on: transaction.block_height == block.height,
        left_join: coinbase_transaction in CoinbaseTransaction,
        on: transaction.hash == coinbase_transaction.hash,
        left_join: security_transaction in SecurityTransaction,
        on: transaction.hash == security_transaction.hash,
        left_join: data_credit_transaction in DataCreditTransaction,
        on: transaction.hash == data_credit_transaction.hash,
        left_join: election_transaction in ElectionTransaction,
        on: transaction.hash == election_transaction.hash,
        left_join: payment_transaction in PaymentTransaction,
        on: transaction.hash == payment_transaction.hash,
        left_join: gateway_transaction in GatewayTransaction,
        on: transaction.hash == gateway_transaction.hash,
        left_join: location_transaction in LocationTransaction,
        on: transaction.hash == location_transaction.hash,
        order_by: [desc: block.height, desc: transaction.id],
        select: [
          coinbase_transaction,
          payment_transaction,
          gateway_transaction,
          location_transaction,
          security_transaction,
          data_credit_transaction,
          election_transaction
        ]
      )

    query
    |> Repo.all()
    |> format_transactions()
  end

  def at_height(block_height, _params) do
    query =
      from(block in Block,
        where: block.height == ^block_height,
        left_join: transaction in Transaction,
        on: block.height == transaction.block_height,
        left_join: coinbase_transaction in CoinbaseTransaction,
        on: transaction.hash == coinbase_transaction.hash,
        left_join: security_transaction in SecurityTransaction,
        on: transaction.hash == security_transaction.hash,
        left_join: data_credit_transaction in DataCreditTransaction,
        on: transaction.hash == data_credit_transaction.hash,
        left_join: election_transaction in ElectionTransaction,
        on: transaction.hash == election_transaction.hash,
        left_join: payment_transaction in PaymentTransaction,
        on: transaction.hash == payment_transaction.hash,
        left_join: gateway_transaction in GatewayTransaction,
        on: transaction.hash == gateway_transaction.hash,
        left_join: location_transaction in LocationTransaction,
        on: transaction.hash == location_transaction.hash,
        left_join: poc_request_transaction in POCRequestTransaction,
        on: transaction.hash == poc_request_transaction.hash,
        left_join: poc_receipts_transaction in POCReceiptsTransaction,
        on: transaction.hash == poc_receipts_transaction.hash,
        left_join: rewards_txn in RewardsTransaction,
        on: transaction.hash == rewards_txn.hash,
        order_by: [
          desc: block.height,
          desc: transaction.id,
          desc: payment_transaction.nonce,
          desc: location_transaction.nonce
        ],
        select: %{
          time: block.time,
          height: block.height,
          coinbase: coinbase_transaction,
          security: security_transaction,
          data_credit: data_credit_transaction,
          election: election_transaction,
          payment: payment_transaction,
          gateway: gateway_transaction,
          location: location_transaction,
          poc_request: poc_request_transaction,
          poc_receipts: poc_receipts_transaction,
          rewards: rewards_txn
        }
      )

    query
    |> Repo.all()
    |> format_blocks()
  end

  def type(hash) do
    Repo.one(
      from t in Transaction,
        where: t.hash == ^hash,
        select: t.type
    )
  end

  def get!(txn_hash) do
    Transaction
    |> where([t], t.hash == ^txn_hash)
    |> Repo.one!()
  end

  def create(block_height, attrs \\ %{}) do
    %Transaction{block_height: block_height}
    |> Transaction.changeset(attrs)
    |> Repo.insert()
  end

  def get_payment!(txn_hash) do
    from(
      transaction in Transaction,
      where: transaction.hash == ^txn_hash,
      left_join: block in Block,
      on: transaction.block_height == block.height,
      left_join: payment_transaction in PaymentTransaction,
      on: transaction.hash == payment_transaction.hash,
      select: %{
        height: block.height,
        time: block.time,
        payee: payment_transaction.payee,
        payer: payment_transaction.payer,
        nonce: payment_transaction.nonce,
        amount: payment_transaction.amount,
        fee: payment_transaction.fee,
        hash: payment_transaction.hash
      }
    )
    |> Repo.one!()
  end

  def get_coinbase!(txn_hash) do
    from(
      transaction in Transaction,
      where: transaction.hash == ^txn_hash,
      left_join: block in Block,
      on: transaction.block_height == block.height,
      left_join: coinbase_transaction in CoinbaseTransaction,
      on: transaction.hash == coinbase_transaction.hash,
      select: %{
        height: block.height,
        time: block.time,
        payee: coinbase_transaction.payee,
        amount: coinbase_transaction.amount,
        hash: coinbase_transaction.hash
      }
    )
    |> Repo.one!()
  end

  def get_security!(txn_hash) do
    from(
      transaction in Transaction,
      where: transaction.hash == ^txn_hash,
      left_join: block in Block,
      on: transaction.block_height == block.height,
      left_join: security_transaction in SecurityTransaction,
      on: transaction.hash == security_transaction.hash,
      select: %{
        height: block.height,
        time: block.time,
        payee: security_transaction.payee,
        amount: security_transaction.amount,
        hash: security_transaction.hash
      }
    )
    |> Repo.one!()
  end

  def get_data_credit!(txn_hash) do
    from(
      transaction in Transaction,
      where: transaction.hash == ^txn_hash,
      left_join: block in Block,
      on: transaction.block_height == block.height,
      left_join: data_credit_transaction in DataCreditTransaction,
      on: transaction.hash == data_credit_transaction.hash,
      select: %{
        height: block.height,
        time: block.time,
        payee: data_credit_transaction.payee,
        amount: data_credit_transaction.amount,
        hash: data_credit_transaction.hash
      }
    )
    |> Repo.one!()
  end

  def get_election!(txn_hash) do
    from(
      transaction in Transaction,
      where: transaction.hash == ^txn_hash,
      left_join: block in Block,
      on: transaction.block_height == block.height,
      left_join: election_transaction in ElectionTransaction,
      on: transaction.hash == election_transaction.hash,
      select: %{
        height: block.height,
        time: block.time,
        proof: election_transaction.proof,
        delay: election_transaction.delay,
        hash: election_transaction.hash,
        election_height: election_transaction.height
      }
    )
    |> Repo.one!()
  end

  def get_gateway!(txn_hash) do
    from(
      transaction in Transaction,
      where: transaction.hash == ^txn_hash,
      left_join: block in Block,
      on: transaction.block_height == block.height,
      left_join: gateway_transaction in GatewayTransaction,
      on: transaction.hash == gateway_transaction.hash,
      select: %{
        height: block.height,
        time: block.time,
        hash: gateway_transaction.hash,
        gateway: gateway_transaction.gateway,
        owner: gateway_transaction.owner,
        payer: gateway_transaction.payer,
        fee: gateway_transaction.fee,
        staking_fee: gateway_transaction.staking_fee
      }
    )
    |> Repo.one!()
  end

  def get_location!(txn_hash) do
    from(
      transaction in Transaction,
      where: transaction.hash == ^txn_hash,
      left_join: block in Block,
      on: transaction.block_height == block.height,
      left_join: location_transaction in LocationTransaction,
      on: transaction.hash == location_transaction.hash,
      select: %{
        height: block.height,
        time: block.time,
        hash: location_transaction.hash,
        gateway: location_transaction.gateway,
        owner: location_transaction.owner,
        payer: location_transaction.payer,
        fee: location_transaction.fee,
        location: location_transaction.location
      }
    )
    |> Repo.one!()
  end

  # ==================================================================
  # Helper functions
  # ==================================================================
  defp format_transactions(entries) do
    entries
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
  end

  defp format_blocks(entries) do
    entries
    |> Enum.map(fn map -> :maps.filter(fn _, v -> not is_nil(v) end, map) end)
    |> Enum.reduce([], fn map, acc -> [Util.clean_txn_struct(map) | acc] end)
    |> Enum.reject(&is_nil/1)
    |> Enum.reverse()
  end
end
