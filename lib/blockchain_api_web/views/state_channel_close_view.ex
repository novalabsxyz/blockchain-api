defmodule BlockchainAPIWeb.StateChannelCloseView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.StateChannelCloseView

  def render("index.json", data) do
    %{
      data: render_many(data.state_channel_open_txns, StateChannelCloseView, "sc_close.json")
    }
  end

  def render("show.json", %{sc_close: sc_close}) do
    %{data: render_one(sc_close, StateChannelCloseView, "sc_close.json")}
  end

  def render("sc_close.json", %{sc_close: sc_close}) do
    sc_close
  end
end
