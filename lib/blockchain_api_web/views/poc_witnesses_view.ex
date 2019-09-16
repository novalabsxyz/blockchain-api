defmodule BlockchainAPIWeb.POCWitnessesView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.POCWitnessesView

  def render("index.json", data) do
    %{
      data: render_many(data.poc_witnesses, POCWitnessesView, "poc_witnesses.json")
    }
  end

  def render("show.json", %{poc_witnesses: poc_witnesses}) do
    %{data: render_one(poc_witnesses, POCWitnessesView, "poc_witnesses.json")}
  end

  def render("poc_witnesses.json", %{poc_witnesses: poc_witnesses}) do
    poc_witnesses
  end
end
