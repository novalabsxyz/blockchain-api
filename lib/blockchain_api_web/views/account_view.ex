defmodule BlockchainAPIWeb.AccountView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.AccountView

  def render("index.json", page) do
    %{
      data: render_many(page.accounts, AccountView, "account.json"),
      page_number: page.page_number,
      page_size: page.page_size,
      total_pages: page.total_pages,
      total_entries: page.total_entries
    }
  end

  def render("show.json", %{account: account}) do
    %{data: render_one(account, AccountView, "account.json")}
  end

  def render("account.json", %{account: account}) do
    account
  end

end
