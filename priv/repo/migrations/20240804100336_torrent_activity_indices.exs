defmodule Elixpeer.Repo.Migrations.TorrentActivityIndices do
  use Ecto.Migration

  def change do
    execute "ALTER TABLE torrent_activities SET (timescaledb.compress, timescaledb.compress_orderby='inserted_at', timescaledb.compress_segmentby='torrent_id');"
  end
end
