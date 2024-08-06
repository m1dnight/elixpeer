defmodule Elixpeer.TorrentActivities do
  @moduledoc """
  Functions to deal with TorrentActivities in the database.
  """
  alias Ecto.Adapters.SQL
  alias Elixpeer.Repo
  alias Elixpeer.TorrentActivity

  require Logger

  @doc """
  Inserts a torrent activity into the database.
  """
  @spec insert(map()) :: TorrentActivity.t()
  def insert(attrs) do
    %TorrentActivity{}
    |> TorrentActivity.changeset(attrs)
    |> Repo.insert!(
      on_conflict: :replace_all,
      conflict_target: [:torrent_id, :inserted_at],
      returning: true
    )
  end

  @doc """
  Get the average total up- and download speeds and volume of all torrents combined
  per hour.
  """
  @spec torrent_activities([interval_days: integer()] | []) :: [
          %{
            bucket: DateTime.t(),
            uploaded: Decimal.t(),
            downloaded: Decimal.t(),
            upload_speed_bps: Decimal.t(),
            download_speed_bps: Decimal.t()
          }
        ]
  def torrent_activities(opts \\ [interval_days: 5]) do
    opts = Keyword.validate!(opts, interval_days: 5)
    interval_days = opts[:interval_days]

    query = """
    WITH buckets AS (SELECT time_bucket('1 hour', inserted_at)                         AS bucket,
                        last(uploaded, inserted_at) - first(uploaded, inserted_at)     AS uploaded,
                        last(downloaded, inserted_at) - first(downloaded, inserted_at) AS downloaded,
                        torrent_id                                                     AS torrent_id
                 FROM torrent_activities
                 WHERE inserted_at > NOW() - INTERVAL '#{interval_days} day'
                   AND inserted_at <= NOW()
                 GROUP BY bucket, torrent_id)
    SELECT time_bucket_gapfill('1 hour', bucket) AS bucky,
       SUM(uploaded)                         AS uploaded,
       SUM(downloaded)                       AS downloaded,
       SUM(uploaded) * 8 / 3600              AS upload_speed_bps,
       SUM(downloaded) * 8 / 3600            AS download_speed_bps
    FROM buckets
    WHERE bucket > NOW() - INTERVAL '#{interval_days}  day'
    AND bucket <= NOW()
    GROUP BY bucky;

    """

    case SQL.query(Elixpeer.Repo, query, []) do
      {:ok, %{rows: rows}} ->
        Enum.map(rows, fn [bucket, uploaded, downloaded, upload_speed_bps, download_speed_bps] ->
          %{
            bucket: bucket,
            uploaded: uploaded,
            downloaded: downloaded,
            upload_speed_bps: upload_speed_bps,
            download_speed_bps: download_speed_bps
          }
        end)

      err ->
        Logger.error("error when querying torrent stats: #{inspect(err)}")
        []
    end
  end

  @doc """
  Get the aggregated up- and download speeds of a specific torrent for the last 2 days.
  """
  @spec torrent_speeds(integer()) :: list(list())
  def torrent_speeds(torrent_id) do
    query = """
    with uploaded as (SELECT inserted_at,
                            (
                                CASE
                                    WHEN uploaded >= lag(uploaded) OVER w
                                        THEN uploaded - lag(uploaded) OVER w
                                    WHEN lag(uploaded) OVER w IS NULL THEN null
                                    ELSE uploaded
                                    END
                                ) AS total_upload,
                            (
                                CASE
                                    WHEN downloaded >= lag(downloaded) OVER w
                                        THEN downloaded - lag(downloaded) OVER w
                                    WHEN lag(downloaded) OVER w IS NULL THEN null
                                    ELSE downloaded
                                    END
                                ) AS total_download
                      FROM torrent_activities
                      WHERE torrent_id = #{torrent_id}
                      WINDOW w AS (ORDER BY inserted_at)
                      ORDER BY inserted_at asc)
    SELECT time_bucket_gapfill('1 hour', inserted_at) AS bucket, sum(total_upload), sum(total_download) as volume
    FROM uploaded
    WHERE inserted_at > now() - interval '2 day'
      and inserted_at <= now()
    GROUP BY bucket
    ORDER BY bucket desc;
    """

    case SQL.query(Elixpeer.Repo, query, []) do
      {:ok, %{rows: rows}} -> rows
      _ -> []
    end
  end

  @doc """
  Get the aggregated up- and download speeds of all torrents combined for the last 5 days.
  """
  @spec torrent_volume(integer()) :: list(list())
  def torrent_volume(torrent_id) do
    query = """
      SELECT time_bucket_gapfill('1 hour', inserted_at)                    AS bucket,
            last(uploaded, inserted_at) - first(uploaded, inserted_at)     AS uploaded,
            last(downloaded, inserted_at) - first(downloaded, inserted_at) AS downloaded
      FROM torrent_activities
      WHERE inserted_at > NOW() - INTERVAL '5 day'
        AND inserted_at <= NOW()
        AND torrent_id = #{torrent_id}
      GROUP BY bucket;
    """

    case SQL.query(Elixpeer.Repo, query, []) do
      {:ok, %{rows: rows}} -> rows
      _ -> []
    end
  end
end
