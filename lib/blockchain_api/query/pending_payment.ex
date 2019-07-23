defmodule BlockchainAPI.Query.PendingPayment do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.PendingPayment}

  def create(attrs \\ %{}) do
    %PendingPayment{}
    |> PendingPayment.changeset(attrs)
    |> Repo.insert()
  end

  def list_pending() do
    PendingPayment
    |> where([pp], pp.status == "pending")
    |> Repo.all
  end

  def get!(hash) do
    PendingPayment
    |> where([pp], pp.hash == ^hash)
    |> Repo.one!
  end

  def get_by_id!(id) do
    PendingPayment
    |> where([pp], pp.id == ^id)
    |> Repo.one!()
  end

  def update!(pp, attrs \\ %{}) do
    pp
    |> PendingPayment.changeset(attrs)
    |> Repo.update!()
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

  def get_pending_by_address(address) do
    from(
      pp in PendingPayment,
      where: pp.payee == ^address,
      or_where: pp.payer == ^address,
      where: pp.status == "pending",
      where: pp.status != "error",
      where: pp.status != "cleared",
      select: pp
    )
    |> Repo.all()
    |> format()
  end

  def get(payer, nonce) do
    from(
      pp in PendingPayment,
      where: pp.payer == ^payer,
      where: pp.nonce == ^nonce,
      select: pp
    )
    |> Repo.one()
    |> format_one()
  end

  def delete!(pp) do
    pp |> Repo.delete!()
  end

  #==================================================================
  # Helper functions
  #==================================================================
  defp format(entries) do
    entries
    |> Enum.map(&format_one/1)
  end

  defp format_one(nil), do: %{}
  defp format_one(entry) do
    Map.merge(entry, %{type: "payment"})
  end

end
