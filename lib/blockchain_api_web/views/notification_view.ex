defmodule BlockchainAPIWeb.NotificationView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.NotificationView

  def render("index.json", %{notifications: notifications}) do
    %{
      data: render_many(notifications, NotificationView, "notification.json")
    }
  end

  def render("show.json", %{notification: notification}) do
    %{data: render_one(notification, NotificationView, "notification.json")}
  end

  def render("notification.json", %{notification: notification}) do
    notification
  end
end
