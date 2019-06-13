defmodule BlockchainAPI.Query.History do
  @moduledoc false
  import Ecto.Query, warn: false

  alias BlockchainAPI.{Repo, Schema.History}

  def get(from, to, _params) do
    from(
      h in History,
      where: h.height >= ^from,
      where: h.height <= ^to,
      order_by: [desc: h.id])
    |> Repo.all()
  end

end
