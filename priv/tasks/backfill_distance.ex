defmodule Mix.Tasks.BackfillDistance do
  @start_apps [
    :postgrex,
    :ecto,
    :ecto_sql,
  ]

  @repo BlockchainAPI.Repo

  use Mix.Task

  import Ecto.Query, warn: false

  alias BlockchainAPI.{
    Repo,
    Schema.POCWitness,
    Schema.POCPathElement,
    Util
  }

  defp boot() do
    IO.puts "Booting pre hook..."
    # Ensure postgrex and ecto applications started
    Enum.each(@start_apps, &Application.ensure_all_started/1)
  end

  defp start_connection() do
    {:ok, _ } = @repo.start_link(pool_size: 10)
  end

  # Took ~20s to run locally on ~53k records
  @shortdoc "Backfills poc_witnesses.distance field"
  def run(_) do
    boot()
    start_connection()
    IO.puts("Backfilling distance...")

    query = from(
      wx in POCWitness,
      where: is_nil(wx.distance),
      left_join: path_element in POCPathElement,
      on: wx.poc_path_elements_id == path_element.id,
      select: %{
        wx_id: wx.id,
        wx_loc: wx.location,
        challengee_loc: path_element.challengee_loc
      }
    )

    witnesses_without_distance = query |> Repo.all()

    for %{wx_id: wx_id, wx_loc: wx_loc, challengee_loc: challengee_loc} <- witnesses_without_distance do
      distance = Util.h3_distance_in_meters(
        wx_loc |> Util.h3_from_string(),
        challengee_loc |> Util.h3_from_string()
      )
      %POCWitness{id: wx_id}
      |> POCWitness.changeset(%{distance: distance})
      |> Repo.update()
    end
  end
end
