defmodule Elixpeer.TorrentActivitiesTest do
  use Elixpeer.DataCase

  alias Elixpeer.Torrents
  alias Elixpeer.Trackers
  alias Elixpeer.TorrentActivities

  setup do
    # insert a torrent
    # attrs = %{
    #   name: "PD.True.S01E08.1080p.WEB.H264-BUSSY",
    #   status: :seeding,
    #   upload_ratio: 0.0,
    #   added_date: ~U[2024-07-27 20:39:03Z],
    #   trackers: [],
    #   activity_date: ~U[2024-08-02 20:22:15Z],
    #   downloaded: 0,
    #   is_finished: false,
    #   percent_done: 0,
    #   rate_download: 0,
    #   rate_upload: 0,
    #   size_when_done: 0,
    #   uploaded: 0
    # }

    # torrent = Torrents.upsert(@torrent_attrs)
    # %{torrent: torrent}
    %{}
  end

  describe "insert activities" do
    test "insert activity", context do
      # activity_attrs = %{
      #   torrent_id: context.torrent.id,
      #   upload: 0,
      #   uploaded: 0,
      #   download: 0,
      #   downloaded: 0
      # }

      # # insert the activity
      # result = TorrentActivities.insert(activity_attrs)

      # # assert TorrentActivities.list() == [result]
    end
  end
end
