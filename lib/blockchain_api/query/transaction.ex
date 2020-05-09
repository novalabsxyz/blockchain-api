defmodule BlockchainAPI.Query.Transaction do
  @moduledoc false
  import Ecto.Query, warn: false

  # number of previous blocks to look for poc request txns
  @past_poc_req_blocks 5

  require Logger

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
    Schema.OUITransaction,
    Schema.SecurityExchangeTransaction,
    Schema.PaymentV2Txn,
    Schema.StateChannelOpenTxn,
    Schema.StateChannelCloseTxn,
    Util
  }

  alias Ecto.Multi

  def get(block_height) do
    get_by_height(block_height)
  end

  def type(hash) do
    Repo.replica.one(
      from t in Transaction,
        where: t.hash == ^hash,
        select: t.type
    )
  end

  def get!(txn_hash) do
    Transaction
    |> where([t], t.hash == ^txn_hash)
    |> Repo.replica.one!()
  end

  def create(block_height, attrs \\ %{}) do
    %Transaction{block_height: block_height}
    |> Transaction.changeset(attrs)
    |> Repo.insert()
  end

  def insert_all(block_height, transactions) do
    inserted_at = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
    updated_at = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
    txn_changesets = transactions
                     |> Enum.map(
                       fn(t) ->
                         meta = %{
                           inserted_at: inserted_at,
                           updated_at: updated_at,
                           block_height: block_height
                         }
                         Map.merge(t, meta)
                       end)

    res = Multi.new()
          |> Multi.insert_all(:insert_all_txns, Transaction, txn_changesets, returning: [:id, :block_height, :hash, :type])
          |> Repo.transaction()

    case res do
      {:error, reason}=e ->
        Logger.error("batch inserted txns error: #{inspect(reason)}")
        e
      {:ok, batch_txns} ->
        {:ok, batch_txns}
    end
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
    |> Repo.replica.one!()
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
    |> Repo.replica.one!()
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
    |> Repo.replica.one!()
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
    |> Repo.replica.one!()
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
    |> Repo.replica.one!()
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
    |> Repo.replica.one!()
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
    |> Repo.replica.one!()
  end

  def get_ongoing_poc_requests() do
    ongoing_subquery =
      from(
        txn in Transaction,
        where: txn.type == "poc_request",
        left_join: req in POCRequestTransaction,
        on: txn.hash == req.hash,
        left_join: rx in POCReceiptsTransaction,
        on: req.id == rx.poc_request_transactions_id and is_nil(rx.id),
        group_by: txn.block_height,
        order_by: [desc: txn.block_height],
        limit: @past_poc_req_blocks,
        select: %{count: count(txn.block_height)}
      )

    q =
      from(
        q in subquery(ongoing_subquery),
        select: sum(q.count)
      )

    case Repo.replica.one(q) do
      nil ->
        0

      res ->
        Decimal.to_integer(res)
    end
  end

  def get_payment_v2!(txn_hash) do
    from(
      transaction in Transaction,
      where: transaction.hash == ^txn_hash,
      left_join: block in Block,
      on: transaction.block_height == block.height,
      left_join: payment_v2_txn in PaymentV2Txn,
      on: transaction.hash == payment_v2_txn.hash,
      select: %{
        height: block.height,
        time: block.time,
        payments: payment_v2_txn.payments,
        payer: payment_v2_txn.payer,
        nonce: payment_v2_txn.nonce,
        fee: payment_v2_txn.fee,
        hash: payment_v2_txn.hash
      }
    )
    |> Repo.replica.one!()
  end

  # ==================================================================
  # Helper functions
  # ==================================================================

  defp get_by_height(block_height) do
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
        left_join: oui_txn in OUITransaction,
        on: transaction.hash == oui_txn.hash,
        left_join: sec_exchange_txn in SecurityExchangeTransaction,
        on: transaction.hash == sec_exchange_txn.hash,
        left_join: payment_v2 in PaymentV2Txn,
        on: transaction.hash == payment_v2.hash,
        left_join: sc_open_txn in StateChannelOpenTxn,
        on: transaction.hash == sc_open_txn.hash,
        left_join: sc_close_txn in StateChannelCloseTxn,
        on: transaction.hash == sc_close_txn.hash,
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
          rewards: rewards_txn,
          oui: oui_txn,
          sec_exchange: sec_exchange_txn,
          payment_v2: payment_v2,
          sc_open: sc_open_txn,
          sc_close: sc_close_txn
        }
      )

    query
    |> Repo.replica.all()
    |> encode()
  end

  # Encoding helpers
  defp encode(entries) do
    entries
    |> Enum.map(fn map -> :maps.filter(fn _, v -> not is_nil(v) end, map) end)
    |> Enum.reduce([], fn map, acc -> [Util.clean_txn_struct(map) | acc] end)
    |> Enum.reject(&is_nil/1)
    |> Enum.reverse()
  end
end
