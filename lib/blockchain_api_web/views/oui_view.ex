defmodule BlockchainAPIWeb.OUIView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.OUIView

  def render("index.json", data) do
    %{
      data: render_many(data.ouis, OUIView, "oui.json")
    }
  end

  def render("show.json", %{oui: oui}) do
    %{data: render_one(oui, OUIView, "oui.json")}
  end

  def render("oui.json", %{oui: oui}) do
    oui
  end
end
