defmodule BlockchainAPI.Release.Tasks do

  @start_apps [
    :postgrex,
    :ecto,
    :ecto_sql
  ]

  @myapps [
    :blockchain_api
  ]

  @repos [
    BlockchainAPI.Repo
  ]

  def createdb do

    # Ensure all apps have started
    Enum.each(@myapps, fn(x) ->
      case Application.load(x) do
        :ok ->
          :ok
        {:error, {:already_loaded, _}} ->
          :ok
      end
    end)

    # Start postgrex and ecto
    Enum.each(@start_apps, fn(x) ->
      {:ok, _} = Application.ensure_all_started(x)
    end)

    # Create the database if it doesn't exist
    Enum.each(@repos, &ensure_repo_created/1)

    :init.stop()
  end

  def migrate do

    IO.puts "Starting dependencies"
    # Start apps necessary for executing migrations
    Enum.each(@start_apps, &Application.ensure_all_started/1)

    # Start the Repo(s) for myapp
    IO.puts "Starting repos"
    Enum.each(@repos, &(&1.start_link(pool_size: 2)))

    # Run migrations
    Enum.each(@myapps, fn(myapp) ->
      run_migrations_for(myapp)
    end)

  end

  def priv_dir(app), do: "#{:code.priv_dir(app)}"

  defp run_migrations_for(app) do
    IO.puts "Running migrations for #{app}"
    Ecto.Migrator.run(BlockchainAPI.Repo, migrations_path(app), :up, all: true)
  end

  defp migrations_path(app), do: Path.join([priv_dir(app), "repo", "migrations"])

  defp ensure_repo_created(repo) do
    case repo.__adapter__.storage_up(repo.config) do
      :ok -> :ok
      {:error, :already_up} -> :ok
      {:error, term} -> {:error, term}
    end
  end

end
