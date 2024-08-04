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
    |> Repo.insert!()
  end

  @spec average_upload_speed() :: list(TorrentActivity.t())
  def average_upload_speed do
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
end
