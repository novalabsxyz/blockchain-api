defmodule Mix.Tasks.BackfillHotspotName do
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
    Schema.Hotspot,
    Query
  }

  defp boot() do
    IO.puts "Booting pre hook..."
    # Ensure postgrex and ecto applications started
    Enum.each(@start_apps, &Application.ensure_all_started/1)
  end

  defp start_connection() do
    {:ok, _ } = @repo.start_link(pool_size: 10)
    {:ok, _ } = @repo.replica.start_link(pool_size: 10)
  end

  @shortdoc "Backfills hotspot.name field"
  def run(_) do
    boot()
    start_connection()
    IO.puts("Backfilling hotspot names...")

    query = from(
      h in Hotspot,
      where: h.name == ""
    )

    query
    |> IO.inspect()
    |> Repo.replica.all()
    |> IO.inspect()
    |> Enum.map(
      fn(hotspot) ->
        IO.inspect hotspot
        Query.Hotspot.update(hotspot, %{name: Hotspot.animal_name(hotspot.address)})
      end)
  end
end
