defmodule BlockchainAPI.Query.Notification do
  @moduledoc false
  import Ecto.Query, warn: false

  @default_limit 100
  @max_limit 1000

  alias BlockchainAPI.{
    Repo,
    Util,
    Schema.Notification
  }

  # ==================================================================
  # Public functions
  # ==================================================================
  def list(address, params) do
    base_query(address)
    # |> maybe_filter(params)
    |> Repo.all()
  end

  def create(attrs \\ %{}) do
    %Notification{}
    |> Notification.changeset(attrs)
    |> Repo.insert()
  end

  # ==================================================================
  # Helper functions
  # ==================================================================

  # Query helpers
  defp base_query(address) do
    from(n in Notification,
      where: n.account_address == ^address,
      order_by: [desc: n.id]
    )
  end

  # defp maybe_filter(query, %{"before" => before, "limit" => limit0} = _params) do
  #   limit = min(@max_limit, String.to_integer(limit0))

  #   query
  #   |> where([block], block.height < ^before)
  #   |> limit(^limit)
  # end

  # defp maybe_filter(query, %{"before" => before} = _params) do
  #   query
  #   |> where([block], block.height < ^before)
  #   |> limit(@default_limit)
  # end

  # defp maybe_filter(query, %{"limit" => limit0} = _params) do
  #   limit = min(@max_limit, String.to_integer(limit0))

  #   query
  #   |> limit(^limit)
  # end

  # defp maybe_filter(query, %{}) do
  #   query
  #   |> limit(@default_limit)
  # end
end
