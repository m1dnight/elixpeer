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
  describe "upsert/1" do
    test "insert new torrent" do
      # upsert the torrent
      result = Torrents.upsert(@torrent_attrs)

      assert Torrents.list() == [result]
    end

    test "insert duplicate torrent upserts" do
      result1 = Torrents.upsert(@torrent_attrs)
      result2 = Torrents.upsert(@torrent_attrs)

      assert result1.id == result2.id
    end

    test "inserts trackers too" do
      Torrents.upsert(@torrent_attrs)

      assert Enum.count(Trackers.list()) == 2
    end

    test "inserts trackers too, without duplicates" do
      _result1 = Torrents.upsert(@torrent_attrs)
      _result2 = Torrents.upsert(@torrent_attrs)

      assert Enum.count(Trackers.list()) == 2
    end
  end
end
