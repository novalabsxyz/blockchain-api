defmodule BlockchainAPIWeb.POCReceiptsView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.POCReceiptsView

  def render("index.json", data) do
    %{
      data: render_many(data.poc_receipts, POCReceiptsView, "poc_receipts.json"),
    }
  end

  def render("show.json", %{poc_receipts: poc_receipts}) do
    %{data: render_one(poc_receipts, POCReceiptsView, "poc_receipts.json")}
  end

  def render("poc_receipts.json", %{poc_receipts: poc_receipts}) do
    poc_receipts
  end
end
