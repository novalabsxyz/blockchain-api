defmodule BlockchainAPI.Query.LocationTransaction do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.LocationTransaction}

  def list_location_transactions(params) do
    LocationTransaction
    |> Repo.paginate(params)
  end

  def get_location!(hash) do
    LocationTransaction
    |> where([lt], lt.hash == ^hash)
    |> Repo.one!
  end

  def create_location(txn_hash, attrs \\ %{}) do
    %LocationTransaction{hash: txn_hash}
    |> LocationTransaction.changeset(attrs)
    |> Repo.insert()
  end
end
