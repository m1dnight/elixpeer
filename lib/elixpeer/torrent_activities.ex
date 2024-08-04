defmodule Elixpeer.TorrentActivities do
  @moduledoc """
  Functions to deal with TorrentActivities in the database.
  """
  alias Ecto.Adapters.SQL
  alias Elixpeer.Repo
  alias Elixpeer.TorrentActivity

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

  @spec average_speed() :: list(TorrentActivity.t())
  def average_speed do
    query = """
    with avg_per_torrent as (SELECT time_bucket_gapfill('60 minute', inserted_at) as bucket,
                                    avg(upload)                                   as upload,
                                    avg(download)                                 as download,
                                    torrent_id                                    as torrent

                            FROM torrent_activities
                            WHERE inserted_at > NOW() - INTERVAL '5 days'
                              and inserted_at <= now()
                            GROUP BY bucket, torrent_id
                            ORDER BY bucket DESC)
    select bucket, sum(upload), sum(download)
    from avg_per_torrent
    group by bucket
    order by bucket desc;
    """

    case SQL.query!(Elixpeer.Repo, query, []) do
      %{rows: rows} -> rows
      _ -> []
    end
  end

  @spec volume() :: list()
  def volume do
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
                      where torrent_id = 66
                      WINDOW w AS (ORDER BY inserted_at)
                      ORDER BY inserted_at asc)
    SELECT time_bucket_gapfill('1 hour', inserted_at) AS bucket, sum(total_upload), sum(total_download) as volume
    FROM uploaded
    WHERE inserted_at > now() - interval '5 day'
      and inserted_at <= now()
    GROUP BY bucket
    ORDER BY bucket desc;
    """

    case SQL.query!(Elixpeer.Repo, query, []) do
      %{rows: rows} -> rows
      _ -> []
    end
  end
end
