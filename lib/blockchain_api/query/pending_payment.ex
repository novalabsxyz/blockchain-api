defmodule BlockchainAPI.Query.PendingPayment do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.PendingPayment}

  def create(attrs \\ %{}) do
    %PendingPayment{}
    |> PendingPayment.changeset(attrs)
    |> Repo.insert()
  end

  def get!(hash) do
    PendingPayment
    |> where([pp], pp.hash == ^hash)
    |> Repo.one!
  end

  def update!(pp, attrs \\ %{}) do
    pp
    |> PendingPayment.changeset(attrs)
    |> Repo.update!()
  end

  def delete!(pp, attrs \\ %{}) do
    pp
    |> PendingPayment.changeset(attrs)
    |> Repo.delete!()
  end

  def get_by_address(address) do
    query = from(
      pp in PendingPayment,
      where: pp.payee == ^address or pp.payer == ^address,
      select: pp
    )

    query
    |> Repo.all()
    |> format()
  end

  def get_payee_pending(address) do
    fifteen_mins_ago = Timex.to_naive_datetime(Timex.shift(Timex.now(), minutes: -15))

    from(
      pp in PendingPayment,
      where: pp.payee == ^address,
      where: pp.status == "pending",
      where: pp.inserted_at >= ^fifteen_mins_ago,
      select: pp
    )
    |> Repo.all()
    |> format()
  end

  #==================================================================
  # Helper functions
  #==================================================================
  defp format(entries) do
    entries
    |> Enum.map(fn(t) -> Map.merge(t, %{type: "payment"}) end)
  end

end
