defmodule BlockchainAPI.Query.Stats do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.Account}

  def list() do
    %{
      "token_supply" => %{
        "total" => get_supply()
      },
      "block_time" => %{
        "7d" => 123.45
      }
    }
  end

  def get_supply() do
    from(
      a in Account,
      select: sum(a.balance)
    )
    |> Repo.one()
    |> Decimal.to_integer()
  end
end
