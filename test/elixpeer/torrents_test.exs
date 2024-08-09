defmodule Elixpeer.TorrentsTest do
  use Elixpeer.DataCase

  alias Elixpeer.Torrents
  alias Elixpeer.Trackers

  @torrent_attrs %{
    name: "PD.True.S01E08.1080p.WEB.H264-BUSSY",
    status: :seeding,
    upload_ratio: 0.2591,
    added_date: ~U[2024-07-27 20:39:03Z],
    trackers: [
      %{
        announce: "https://tracker.com/announce",
        scrape: "https://tracker.com/scrape",
        tier: 0,
        sitename: "tracker.com"
      },
      %{
        announce: "https://tracker2.com/announce",
        scrape: "https://tracker2.com/scrape",
        tier: 0,
        sitename: "tracker2.com"
      }
    ],
    activity_date: ~U[2024-08-02 20:22:15Z],
    downloaded: 1_725_303_631,
    is_finished: false,
    percent_done: 100,
    rate_download: 0,
    rate_upload: 0,
    size_when_done: 1_725_303_631,
    uploaded: 447_100_104
  }
  describe "insert_or_update_torrent" do
    test "insert new torrent" do
      # upsert the torrent
      result = Torrents.upsert(@torrent_attrs)

      assert Torrents.list() == [result]
    end

    test "insert duplicate torrent fails" do
      result1 = Torrents.upsert(@torrent_attrs)
      result2 = Torrents.upsert(@torrent_attrs)


      IO.inspect Torrents.list()
      assert Torrents.list() == [result2]
    end

    test "inserts trackers too" do
      result = Torrents.upsert(@torrent_attrs)

      assert Enum.count(Trackers.list()) == 2
    end

    test "inserts trackers too, without duplicates" do
      _result1 = Torrents.upsert(@torrent_attrs)
      _result2 = Torrents.upsert(@torrent_attrs)

      assert Enum.count(Trackers.list()) == 2
    end

    # test "insert new torrent inserts trackers" do
    #   # upsert the torrent
    #   result = Torrents.upsert(@torrent_attrs)

    #   assert Torrents.list() == [result]
    #   assert Enum.sort(Trackers.list()) == Enum.sort(result.trackers)
    # end

    # test "upsert does not change id" do
    #   # upsert the torrent
    #   result1 = Torrents.upsert(@torrent_attrs)
    #   assert Torrents.list() == [result1]

    #   result2 = Torrents.upsert(@torrent_attrs)
    #   assert Enum.count(Torrents.list()) == 1
    #   assert result1.id == result2.id
    # end

    # test "upsert does not change the trackers" do
    #   # upsert the torrent
    #   result1 = Torrents.upsert(@torrent_attrs)
    #   result2 = Torrents.upsert(@torrent_attrs)

    #   assert Enum.count(Trackers.list()) == 2
    #   assert result1.trackers == result2.trackers
    # end
  end
end
