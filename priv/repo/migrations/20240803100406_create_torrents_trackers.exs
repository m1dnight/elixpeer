defmodule Elixpeer.Repo.Migrations.CreateTorrentsTrackers do
  use Ecto.Migration

  def change do
    create table(:torrents_trackers) do
      add(:torrent_id, references(:torrents, on_delete: :delete_all), primary_key: true)
      add(:tracker_id, references(:trackers, on_delete: :delete_all), primary_key: true)
    end
  end
end
