defmodule BlockchainAPIWeb.ActivityView do
  use BlockchainAPIWeb, :view
  alias BlockchainAPIWeb.ActivityView

  def render("index.json", data) do
	%{
	  data: render_many(data.activity, ActivityView, "activity.json"),
	}
  end

  def render("show.json", %{activity: activity}) do
	%{data: render_one(activity, ActivityView, "activity.json")}
  end

  def render("activity.json", %{activity: activity}) do
	activity
  end
end

