defmodule Elixpeer.Repo.Migrations.AddIndex do
  use Ecto.Migration

  def change do
    create unique_index(:trackers, [:announce, :scrape, :sitename, :tier], nulls_distinct: false)
  end
end
