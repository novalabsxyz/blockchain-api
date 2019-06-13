defmodule BlockchainAPIWeb.HistoryView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.HistoryView

  def render("index.json", data) do
    %{
      data: render_many(data.history, HistoryView, "history.json"),
    }
  end

  def render("history.json", %{history: history}) do
    history
  end
end
