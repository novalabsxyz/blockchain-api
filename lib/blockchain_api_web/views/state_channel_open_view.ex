defmodule BlockchainAPIWeb.StateChannelOpenView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.StateChannelOpenView

  def render("index.json", data) do
    %{
      data: render_many(data.state_channel_open_txns, StateChannelOpenView, "sc_open.json")
    }
  end

  def render("show.json", %{sc_open: sc_open}) do
    %{data: render_one(sc_open, StateChannelOpenView, "sc_open.json")}
  end

  def render("sc_open.json", %{sc_open: sc_open}) do
    sc_open
  end
end
