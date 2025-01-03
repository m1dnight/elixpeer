defmodule Elixpeer.TrackersTest do
  use Elixpeer.DataCase

  alias Elixpeer.Trackers

  @tracker_attrs %{
    announce: "https://tracker.com/announce",
    scrape: "https://tracker.com/scrape",
    tier: 0,
    sitename: "tracker.com"
  }
  @tracker_attrs_no_scrape %{
    announce: "http://bt4.t-ru.org/ann",
    scrape: nil,
    tier: 0,
    sitename: "t-ru"
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

    test "duplicate values no scrape" do
      result1 = Trackers.upsert(@tracker_attrs_no_scrape)
      _result2 = Trackers.upsert(@tracker_attrs_no_scrape)

      assert Trackers.list() == [result1]
    end
  end
end
