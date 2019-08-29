defmodule BlockchainAPI.Query.Util do
  @moduledoc false
  alias BlockchainAPI.Repo

  def list_stream(query, mod) do
    reducer = fn(item, list) -> [item | list] end
    with {:ok, data} <- Repo.transaction(fn() ->
      query
      |> Repo.stream()
      |> Enum.reduce([], reducer)
      |> mod.encode()
    end) do
      data
    end
  end

end
