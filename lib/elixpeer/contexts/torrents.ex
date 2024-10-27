defmodule Elixpeer.Torrents do
  @moduledoc """
  Functions to deal with Torrent structs in the database.
  """
  alias Elixpeer.Repo
  alias Elixpeer.Torrent
  alias Elixpeer.TorrentActivities
  alias Elixpeer.TorrentActivity

  import Ecto.Query

  #############################################################################
  # Get

  @doc """
  Returns a torrent based on its transmission id.
  """
  @spec get(integer()) :: Torrent.t() | nil
  def get(torrent_id) do
    from(t in Torrent, where: t.id == ^torrent_id)
    |> Repo.one()
  end

  @spec list :: Torrent.t()
  def list do
    Repo.all(Torrent)
    |> Repo.preload(:trackers)
  end

  @doc """
  Fetches the activities for the given torrent.
  """
  @spec activities(Torrent.t()) :: [TorrentActivity.t()]
  def activities(torrent) do
    torrent
    |> Repo.preload(:torrent_activities, force: true)
    |> Map.get(:torrent_activities)
  end

  #############################################################################
  # Insert

  @doc """
  Inserts the torrent into the database, updating if necessary.
  """
  @spec upsert(map()) :: Torrent.t()
  def upsert(attrs) do
    # upsert the torrent
    # because an upsert cannot handle assocs, insert the trackers afterwards.
    torrent =
      %Torrent{}
      |> Torrent.changeset(Map.drop(attrs, [:trackers]))
      |> Repo.insert!(
        on_conflict: {:replace_all_except, [:id]},
        conflict_target: [:name],
        returning: true
      )
      |> Repo.preload([:trackers], force: true)

    # upsert the trackers
    torrent =
      torrent
      |> Torrent.changeset(attrs)
      |> Repo.update!()

    # insert the activity
    TorrentActivities.insert(%{
      torrent_id: torrent.id,
      upload: attrs.rate_upload,
      download: attrs.rate_download,
      uploaded: attrs.uploaded,
      downloaded: attrs.downloaded
    })

    torrent
  end

  #############################################################################
  # Parsing

  # type of the json dictionary coming from the Transmission api
  @type torrent_map :: %{
          :addedDate => integer(),
          :downloadedEver => integer(),
          :id => integer(),
          :isFinished => boolean(),
          :name => String.t(),
          :percentDone => float(),
          :rateDownload => integer(),
          :rateUpload => integer(),
          :sizeWhenDone => integer(),
          :uploadRatio => float(),
          :uploadedEver => any(),
          :activityDate => integer(),
          :trackers => [
            %{
              :id => integer(),
              :announce => String.t(),
              :scrape => String.t(),
              :tier => integer(),
              :sitename => String.t()
            }
          ],
          optional(any()) => any()
        }

  @doc """
  The Transmission library returns a torrent as a map with camelcased keys.
  This function converts that map into a map that can be used in changesets.
  """
  @spec from_map(torrent_map()) :: map()
  def from_map(torrent_map) do
    # https://github.com/transmission/transmission/blob/main/docs/rpc-spec.md

    %{
      activity_date: DateTime.from_unix!(torrent_map.activityDate),
      added_date: DateTime.from_unix!(torrent_map.addedDate),
      downloaded: torrent_map.downloadedEver,
      is_finished: torrent_map.isFinished,
      name: torrent_map.name,
      percent_done: torrent_map.percentDone * 100,
      rate_download: torrent_map.rateDownload,
      rate_upload: torrent_map.rateUpload,
      size_when_done: torrent_map.sizeWhenDone,
      status: parse_status(torrent_map),
      upload_ratio: torrent_map.uploadRatio * 1.0,
      uploaded: torrent_map.uploadedEver,
      trackers: parse_trackers(torrent_map),
      transmission_id: torrent_map.id
    }
  end

  @spec parse_status(torrent_map()) ::
          :stopped
          | :queued_to_verify
          | :verifying
          | :queued_to_download
          | :downloading
          | :queued_to_seed
          | :seeding
  defp parse_status(torrent_map) do
    case torrent_map.status do
      0 -> :stopped
      1 -> :queued_to_verify
      2 -> :verifying
      3 -> :queued_to_download
      4 -> :downloading
      5 -> :queued_to_seed
      6 -> :seeding
    end
  end

  defp parse_trackers(torrent_map) do
    torrent_map.trackers
    |> Enum.map(fn tracker ->
      %{
        announce: tracker.announce,
        scrape: tracker.scrape,
        tier: tracker.tier,
        sitename: tracker.sitename
      }
    end)
  end
end
