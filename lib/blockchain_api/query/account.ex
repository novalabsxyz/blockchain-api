defmodule BlockchainAPI.Query.Account do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{
    Repo,
    Util,
    Schema.Account,
    Schema.PendingPayment,
    Schema.PendingGateway,
    Schema.PendingLocation
  }

  def create(attrs \\ %{}) do
    %Account{}
    |> Account.changeset(attrs)
    |> Repo.insert()
  end

  def get!(address) do
    Account
    |> where([a], a.address == ^address)
    |> Repo.one!
  end

  def update!(account, attrs \\ %{}) do
    account
    |> Account.changeset(attrs)
    |> Repo.update!()
  end

  def list(params) do
    Account
    |> Repo.paginate(params)
  end

  def list_all() do
    Account |> Repo.all()
  end

  def update_all_fee(fee) do
    Account
    |> select([:address, :fee])
    |> Repo.update_all(set: [fee: fee, updated_at: NaiveDateTime.utc_now()])
  end

  def get_pending_transactions(address) do
    get_account_pending_payments(address) ++
    get_account_pending_gateways(address) ++
    get_account_pending_locations(address)
  end

  def get_speculative_nonce(address) do
    query_pending_nonce = from(
      pp in PendingPayment,
      where: pp.payer == ^address,
      where: pp.status != "error",
      select: pp.nonce,
      order_by: [desc: pp.id],
      limit: 1
    )

    query_account_nonce = from(
      a in Account,
      where: a.address == ^address,
      select: a.nonce,
      order_by: [desc: a.id],
      limit: 1
    )

    pending_nonce = Repo.one(query_pending_nonce)
    account_nonce = Repo.one(query_account_nonce)
    case {pending_nonce, account_nonce} do
      {nil, nil} ->
        # there is neither a pending_nonce nor an account_nonce
        0
      {nil, account_nonce} ->
        # there is no pending_nonce but an account_nonce
        account_nonce
      {pending_nonce, nil} ->
        # this shouldn't be possible _ideally_
        pending_nonce
      {pending_nonce, account_nonce} ->
        # return the max of pending_nonce, account_nonce
        max(pending_nonce, account_nonce)
    end
  end

  #==================================================================
  # Helper functions
  #==================================================================
  defp get_account_pending_gateways(address) do
    query = from(
      a in Account,
      where: a.address == ^address,
      left_join: pg in PendingGateway,
      on: pg.owner == a.address,
      order_by: [desc: pg.id],
      select: pg
    )

    query
    |> Repo.all
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&clean_pending_gateway/1)
  end

  defp get_account_pending_locations(address) do
    query = from(
      a in Account,
      where: a.address == ^address,
      left_join: pl in PendingLocation,
      on: pl.owner == a.address,
      order_by: [desc: pl.nonce],
      select: pl
    )

    query
    |> Repo.all
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&clean_pending_location/1)
  end

  defp get_account_pending_payments(address) do
    query_sent = from(
      a in Account,
      where: a.address == ^address,
      left_join: pp in PendingPayment,
      on: pp.payer == a.address,
      select: pp
    )

    query_recv = from(
      a in Account,
      where: a.address == ^address,
      left_join: pp in PendingPayment,
      on: pp.payee == a.address,
      select: pp
    )

    total = Repo.all(query_sent) ++ Repo.all(query_recv)

    total
    |> Enum.reject(&is_nil/1)
    |> Enum.sort_by(&(&1.id), &>=/2)
    |> Enum.map(&clean_pending_payment/1)
  end

  defp clean_pending_payment(nil), do: nil
  defp clean_pending_payment(%PendingPayment{}=pending_payment) do
    Map.merge(PendingPayment.encode_model(pending_payment), %{type: "payment"})
  end

  defp clean_pending_gateway(nil), do: nil
  defp clean_pending_gateway(%PendingGateway{}=pending_gateway) do
    Map.merge(PendingGateway.encode_model(pending_gateway), %{type: "gateway"})
  end

  defp clean_pending_location(nil), do: nil
  defp clean_pending_location(%PendingLocation{}=pending_location) do
    {lat, lng} = Util.h3_to_lat_lng(pending_location.location)
    Map.merge(PendingLocation.encode_model(pending_location), %{type: "location", lat: lat, lng: lng})
  end
end
