defmodule Elixpeer.TorrentActivities do
  @moduledoc """
  Functions to deal with TorrentActivities in the database.
  """
  alias Elixpeer.Repo
  alias Elixpeer.TorrentActivity

  require Logger

  import Ecto.Query

  #############################################################################
  # Insert

  @doc """
  Inserts a torrent activity into the database.
  """
  @spec insert(map()) :: TorrentActivity.t()
  def insert(attrs) do
    # check if there is an activity that matches this one save for the timestamps.
    duplicate =
      from(t in TorrentActivity,
        where: t.torrent_id == ^attrs.torrent_id,
        where: t.uploaded == ^attrs.uploaded,
        where: t.upload == ^attrs.upload,
        where: t.downloaded == ^attrs.downloaded,
        where: t.download == ^attrs.download
      )
      |> Repo.one()

    if is_nil(duplicate) do
      activity =
        %TorrentActivity{}
        |> TorrentActivity.changeset(attrs)
        |> Repo.insert!(
          on_conflict: :replace_all,
          conflict_target: [:torrent_id, :inserted_at],
          returning: true
        )

      activity
    else
      duplicate
    end
  end

  #############################################################################
  # Get

  @doc """
  Returns a list for all torrent activities.
  """
  @spec list() :: list(TorrentActivity.t())
  def list() do
    Repo.all(TorrentActivity)
  end
end
