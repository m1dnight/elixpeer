defmodule Elixpeer.Statistics do
  @moduledoc """
  Functions to get statistics from the torrents and torrent activities.
  """

  require Logger

  alias Ecto.Adapters.SQL

  # A bucket that holds the statistics for a specific time frame.
  # Contains total download, upload, and average upload- and download speed.
  @type statistic_bucket :: %{
          bucket: DateTime.t(),
          uploaded: Decimal.t(),
          downloaded: Decimal.t(),
          upload_speed_bps: Decimal.t(),
          download_speed_bps: Decimal.t()
        }
  @doc """
  Get the average total up- and download speeds and volume of all torrents combined
  per hour.
  """
  @spec torrent_activities([interval_days: integer()] | []) :: [statistic_bucket]
  def torrent_activities(opts \\ [interval_days: 5]) do
    opts = Keyword.validate!(opts, interval_days: 5)
    interval_days = opts[:interval_days]

    query = """
    SELECT time_bucket_gapfill('1 day', bucket)     AS bucket_total,
          COALESCE(SUM(uploaded), 0.0)              AS uploaded,
          COALESCE(SUM(downloaded), 0.0)            AS downloaded,
          COALESCE(SUM(uploaded) * 8 / 3600, 0.0)   AS upload_speed_bps,
          COALESCE(SUM(downloaded) * 8 / 3600, 0.0) AS download_speed_bps
    FROM activity_per_day_per_torrent
    WHERE bucket > NOW() - INTERVAL '#{interval_days} day'
      AND bucket <= NOW()
    GROUP BY bucket_total;
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
  @spec torrent_activities_for(integer()) :: [statistic_bucket]
  def torrent_activities_for(torrent_id) do
    query = """
    SELECT time_bucket_gapfill('1 day', bucket)     AS bucket_total,
          COALESCE(SUM(uploaded), 0.0)              AS uploaded,
          COALESCE(SUM(downloaded), 0.0)            AS downloaded,
          COALESCE(SUM(uploaded) * 8 / 3600, 0.0)   AS upload_speed_bps,
          COALESCE(SUM(downloaded) * 8 / 3600, 0.0) AS download_speed_bps
    FROM activity_per_day_per_torrent
    WHERE bucket > NOW() - INTERVAL '60 day'
      AND bucket <= NOW()
      AND torrent_id = #{torrent_id}
    GROUP BY bucket_total;
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
end
