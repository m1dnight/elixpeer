defmodule Elixpeer.Repo.Migrations.MoarIndices do
  use Ecto.Migration

  def change do
    #############################################################################
    # Remove duplicate assocs

    # list the unique assocs
    execute """
    CREATE TEMPORARY TABLE torrents_trackers_2 AS
    WITH cte AS (SELECT id,
                    torrent_id,
                    tracker_id,
                    ROW_NUMBER() OVER (PARTITION BY torrent_id, tracker_id ORDER BY torrent_id) AS rn
             FROM torrents_trackers)
    SELECT *
    FROM cte
    WHERE rn = 1;
    """

    # delete all assocs
    execute """
    DELETE
    FROM torrents_trackers;
    """

    # reinsert the unique assocs
    execute """
    INSERT INTO torrents_trackers
    SELECT id, torrent_id, tracker_id
    FROM torrents_trackers_2;
    """

    #############################################################################
    # Make torrent activities unique

    # create a table with unique measurements
    execute """
    CREATE TEMPORARY TABLE torrent_activities_2 AS
    WITH cte AS (SELECT torrent_id,
                        upload,
                        uploaded,
                        download,
                        downloaded,
                        inserted_at,
                        ROW_NUMBER() OVER (PARTITION BY torrent_id, upload, uploaded, download, downloaded ORDER BY torrent_id) AS rn
                FROM torrent_activities)
    SELECT *
    FROM cte
    WHERE rn = 1;
    """

    # delete all measurements
    execute """
    delete from torrent_activities;
    """

    # reinsert the unique measurements
    execute """
    INSERT INTO torrent_activities
    SELECT torrent_id, upload, uploaded, download, downloaded, inserted_at::timestamptz, inserted_at::timestamptz FROM torrent_activities_2;
    """

    # drop the unique table
    execute """
    drop table torrent_activities_2;
    """

    #############################################################################
    # Add indices to torrent id and inserted_at

    # decompress table
    # execute "ALTER TABLE torrent_activities SET (timescaledb.compress=false);"

    # index on torrent id
    create index(:torrent_activities, [:torrent_id])

    # enable compression again
    # execute "ALTER TABLE torrent_activities SET (timescaledb.compress, timescaledb.compress_orderby='inserted_at', timescaledb.compress_segmentby='torrent_id');"
  end
end
