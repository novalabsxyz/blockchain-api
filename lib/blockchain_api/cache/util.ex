defmodule BlockchainAPI.Cache.Util do
  @moduledoc false

  def get(cache, by, fun, expiry) do
    with {_, data} <- Cachex.fetch(cache, by, fun) do
      Cachex.expire(cache, by, expiry)
      data
    end
  end
end
