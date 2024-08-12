defmodule Elixpeer.Repo.Migrations.MaterializedView do
  use Ecto.Migration
  @disable_ddl_transaction true

  def change do
    # drop the old view
    execute "DROP MATERIALIZED VIEW IF EXISTS activity_per_hour_per_torrent;"

    # create the new view
    execute(fn ->
      repo().query!("""
      CREATE MATERIALIZED VIEW IF NOT EXISTS activity_per_hour_per_torrent
                  (bucket, uploaded, downloaded, torrent_id)
                  WITH (timescaledb.continuous)
      AS
      SELECT time_bucket('1 hour', inserted_at)                             AS bucket,
            last(uploaded, inserted_at) - first(uploaded, inserted_at)     AS uploaded,
            last(downloaded, inserted_at) - first(downloaded, inserted_at) AS downloaded,
            torrent_id                                                     AS torrent_id
      FROM torrent_activities
      GROUP BY time_bucket('1 hour', inserted_at), torrent_id;
      """)
    end)
  end
end
