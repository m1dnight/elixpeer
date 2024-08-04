defmodule Elixpeer.TorrentActivities do
  @moduledoc """
  Functions to deal with TorrentActivities in the database.
  """
  alias Elixpeer.Repo
  alias Elixpeer.TorrentActivity

  import Ecto.Query

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
    from(t in TorrentActivity,
      select: %{
        date: selected_as(fragment("time_bucket_gapfill('60 minutes', ?)", t.inserted_at), :date),
        avg_upload: fragment("avg(?)", t.upload),
        avg_download: fragment("avg(?)", t.download)
      },
      where: t.inserted_at > fragment("now() - interval '1 day'"),
      where: t.inserted_at <= fragment("now()"),
      group_by: fragment("date"),
      order_by: fragment("date asc")
    )
    |> Repo.all()
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

    case Ecto.Adapters.SQL.query!(Elixpeer.Repo, query, []) do
      %{rows: rows} -> rows
      _ -> []
    end
  end
end
