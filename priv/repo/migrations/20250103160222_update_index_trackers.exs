defmodule Elixpeer.Repo.Migrations.UpdateIndexTrackers do
  use Ecto.Migration

  def change do
    drop unique_index(:trackers, [:announce, :scrape, :sitename, :tier])
  end
end
