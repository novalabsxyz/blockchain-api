defmodule BlockchainAPI.Query.StateChannelCloseTxn do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.StateChannelCloseTxn}

  def create(attrs \\ %{}) do
    %StateChannelCloseTxn{}
    |> StateChannelCloseTxn.changeset(attrs)
    |> Repo.insert()
  end
end
