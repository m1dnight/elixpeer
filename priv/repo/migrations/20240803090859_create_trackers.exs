defmodule Elixpeer.Repo.Migrations.CreateTrackers do
  use Ecto.Migration

  def change do
    create table(:trackers) do
      add :announce, :text
      add :scrape, :text
      add :tier, :integer
      add :sitename, :text

      timestamps(type: :timestamptz)
    end

    create unique_index(:trackers, [:announce, :scrape, :sitename, :tier])
  end
end
