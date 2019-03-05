defmodule BlockchainAPIWeb.AccountBalanceView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.AccountBalanceView

  def render("index.json", page) do
    %{
      data: render_many(page.account_balances, AccountBalanceView, "account_balance.json")
    }
  end

  def render("show.json", %{account_balance: account_balance}) do
    %{data: render_one(account_balance, AccountBalanceView, "account_balance.json")}
  end

  def render("account_balance.json", %{account_balance: account_balance}) do
    account_balance
  end
end
