defmodule BlockchainAPIWeb.POCRequestView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.POCRequestView

  def render("index.json", data) do
    %{
      data: render_many(data.poc_request_transactions, POCRequestView, "poc_request.json")
    }
  end

  def render("show.json", %{poc_request: poc_request}) do
    %{data: render_one(poc_request, POCRequestView, "poc_request.json")}
  end

  def render("poc_request.json", %{poc_request: poc_request}) do
    poc_request
  end
end
