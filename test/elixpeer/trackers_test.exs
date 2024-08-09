defmodule Elixpeer.TrackersTest do
  use Elixpeer.DataCase

  alias Elixpeer.Torrents
  alias Elixpeer.Trackers

  @tracker_attrs %{
    announce: "https://tracker.com/announce",
    scrape: "https://tracker.com/scrape",
    tier: 0,
    sitename: "tracker.com"
  }

  describe "insert/1" do
    test "insert tracker" do
      # insert the tracker
      result = Trackers.upsert(@tracker_attrs)

      assert Trackers.list() == [result]
    end

    test "duplicate values do an upsert" do
      # insert the tracker
      result1 = Trackers.upsert(@tracker_attrs)
      result2 = Trackers.upsert(@tracker_attrs)

      assert result1.id == result2.id

      assert Trackers.list() == [result2]
    end
  end
end
