defmodule BlockchainAPI.Query.HotspotActivity do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.HotspotActivity}

  def create(attrs \\ %{}) do
    %HotspotActivity{}
    |> HotspotActivity.changeset(attrs)
    |> Repo.insert()
  end
end
