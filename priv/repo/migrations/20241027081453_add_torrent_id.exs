defmodule Elixpeer.Repo.Migrations.AddTorrentId do
  use Ecto.Migration

  def change do
    alter table(:torrents) do
      add :transmission_id, :integer
    end
  end
end
