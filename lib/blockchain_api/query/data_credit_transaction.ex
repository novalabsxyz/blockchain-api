defmodule BlockchainAPI.Query.DataCreditTransaction do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.DataCreditTransaction}

  def get_balance(address) do
    DataCreditCTransaction
    |> where([ct], ct.payee == ^address)
    |> order_by([ct], [desc: ct.id])
    |> limit(1)
    |> Repo.one()
  end

end
