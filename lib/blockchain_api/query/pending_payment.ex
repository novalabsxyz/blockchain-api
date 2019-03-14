defmodule BlockchainAPI.Query.PendingPayment do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.PendingPayment}

  def create_pending_payment(attrs \\ %{}) do
    %PendingPayment{}
    |> PendingPayment.changeset(attrs)
    |> Repo.insert()
  end

  def get_pending_payment!(hash) do
    PendingPayment
    |> where([pp], pp.hash == ^hash)
    |> Repo.one!
  end

  def update_pending_payment!(pp, attrs \\ %{}) do
    pp
    |> PendingPayment.changeset(attrs)
    |> Repo.update!()
  end
end
