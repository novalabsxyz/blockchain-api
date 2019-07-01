defmodule BlockchainAPI.Query.RewardTxn do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.RewardTxn}

  def create(attrs \\ %{}) do
    %RewardTxn{}
    |> RewardTxn.changeset(attrs)
    |> Repo.insert()
  end
end
