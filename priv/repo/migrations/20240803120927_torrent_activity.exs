defmodule Elixpeer.Repo.Migrations.TorrentActivity do
  use Ecto.Migration

  def change do
    create table(:torrent_activities, primary_key: false) do
      add(:torrent_id, references(:torrents, on_delete: :delete_all))
      add(:upload, :bigint)
      add(:uploaded, :bigint)
      add(:download, :bigint)
      add(:downloaded, :bigint)

      timestamps(type: :timestamptz)
    end

    execute "SELECT create_hypertable('torrent_activities', by_range('inserted_at'));"
  end
end
