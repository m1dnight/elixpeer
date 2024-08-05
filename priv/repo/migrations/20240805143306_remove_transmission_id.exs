defmodule Elixpeer.Repo.Migrations.RemoveTransmissionId do
  use Ecto.Migration

  def change do
    alter table(:torrents) do
      remove :transmission_id
    end

    create unique_index(:torrents, [:name])
  end
end
