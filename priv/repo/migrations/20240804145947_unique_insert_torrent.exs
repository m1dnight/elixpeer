defmodule Elixpeer.Repo.Migrations.UniqueInsertTorrent do
  use Ecto.Migration

  def change do
    # disable compression to add the index
    execute "ALTER TABLE torrent_activities SET (timescaledb.compress=false);"

    # remove duplicates, if there are any
    execute """
      WITH cte AS (
          SELECT
              torrent_id,
              inserted_at,
              ROW_NUMBER() OVER (PARTITION BY torrent_id, inserted_at ORDER BY torrent_id) AS rn
          FROM
              torrent_activities
      )
      DELETE FROM torrent_activities
      WHERE (torrent_id, inserted_at) IN (
          SELECT torrent_id, inserted_at
          FROM cte
          WHERE rn > 1
      );
    """

    # put the index on the table
    create unique_index(:torrent_activities, [:torrent_id, :inserted_at])

    # enable compression again
    execute "ALTER TABLE torrent_activities SET (timescaledb.compress, timescaledb.compress_orderby='inserted_at', timescaledb.compress_segmentby='torrent_id');"
  end
end
