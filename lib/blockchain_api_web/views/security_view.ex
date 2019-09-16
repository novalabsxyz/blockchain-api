defmodule BlockchainAPIWeb.SecurityView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.SecurityView

  def render("index.json", data) do
    %{
      data: render_many(data.security_transactions, SecurityView, "security.json")
    }
  end

  def render("show.json", %{security: security}) do
    %{data: render_one(security, SecurityView, "security.json")}
  end

  def render("security.json", %{security: security}) do
    security
  end
end
