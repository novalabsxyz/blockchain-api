defmodule BlockchainAPI.Query.PendingSecExchange do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.PendingSecExchange}

  def create(attrs \\ %{}) do
    %PendingSecExchange{}
    |> PendingSecExchange.changeset(attrs)
    |> Repo.insert()
  end

  def get!(hash) do
    PendingSecExchange
    |> where([psec], psec.hash == ^hash)
    |> Repo.one!()
  end

  def get_by_id!(id) do
    PendingSecExchange
    |> where([psec], psec.id == ^id)
    |> Repo.one!()
  end

  def update!(psec, attrs \\ %{}) do
    psec
    |> PendingSecExchange.changeset(attrs)
    |> Repo.update!()
  end

  def get_by_address(address) do
    query =
      from(
        psec in PendingSecExchange,
        where: psec.payee == ^address or psec.payer == ^address,
        select: psec
      )
    query
    |> Repo.all()
    |> format()
  end

  # ==================================================================
  # Helper functions
  # ==================================================================
  defp format(entries) do
    entries
    |> Enum.map(&format_one/1)
  end

  defp format_one(nil), do: %{}

  defp format_one(entry) do
    Map.merge(entry, %{type: "security_exchange"})
  end
end
