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

  #==================================================================
  # Helper functions
  #==================================================================
  defp format(entries) do
    entries
    |> Enum.map(fn(t) -> Map.merge(t, %{type: "payment"}) end)
  end

end
