defmodule BlockchainAPIWeb.AccountView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.AccountView

  def render("index.json", data) do
    %{
      data: render_many(data.accounts, AccountView, "account.json"),
    }
  end

  def render("show.json", %{account: account}) do
    %{data: render_one(account, AccountView, "account.json")}
  end

  def render("account.json", %{account: account}) do
    account
  end
end
