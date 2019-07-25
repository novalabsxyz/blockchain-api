defmodule BlockchainAPIWeb.DataCreditView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.DataCreditView

  def render("index.json", data) do
    %{
      data: render_many(data.data_credit_transactions, DataCreditView, "data_credit.json"),
    }
  end

  def render("show.json", %{data_credit: data_credit}) do
    %{data: render_one(data_credit, DataCreditView, "data_credit.json")}
  end

  def render("data_credit.json", %{data_credit: data_credit}) do
    data_credit
  end

end
