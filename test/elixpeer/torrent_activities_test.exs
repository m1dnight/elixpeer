defmodule Elixpeer.TorrentActivitiesTest do
  use Elixpeer.DataCase

  alias Elixpeer.Torrents
  alias Elixpeer.TorrentActivities

  setup do
    # insert a torrent
    attrs = %{
      name: "PD.True.S01E08.1080p.WEB.H264-BUSSY",
      status: :seeding,
      upload_ratio: 0.0,
      added_date: ~U[2024-07-27 20:39:03Z],
      trackers: [],
      activity_date: ~U[2024-08-02 20:22:15Z],
      downloaded: 0,
      is_finished: false,
      percent_done: 0,
      rate_download: 0,
      rate_upload: 0,
      size_when_done: 0,
      uploaded: 0
    }

    torrent = Torrents.upsert(attrs)
    %{torrent: torrent}
  end

  describe "insert activities" do
    test "activity inserted by inserting torrent", context do
      activities = Torrents.activities(context.torrent)

      assert Enum.count(activities) == 1
    end

    test "duplicates are not inserted", context do
      activities = Torrents.activities(context.torrent)
      assert Enum.count(activities) == 1

      TorrentActivities.insert(%{
        torrent_id: context.torrent.id,
        upload: 0,
        download: 0,
        uploaded: 0,
        downloaded: 0
      })

      activities = Torrents.activities(context.torrent)
      assert Enum.count(activities) == 1
    end
  end
end
