defmodule BlockchainAPI.Query.DCTransaction do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.DCTransaction}

  def get_balance(address) do
    DCTransaction
    |> where([ct], ct.payee == ^address)
    |> order_by([ct], [desc: ct.id])
    |> limit(1)
    |> Repo.one()
  end

end
