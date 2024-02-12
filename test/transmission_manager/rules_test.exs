defmodule TransmissionManager.RulesTest do
  use TransmissionManager.DataCase, async: true

  import TransmissionManager.Rules
  import TransmissionManager.Fixtures

  #############################################################################
  # Helpers

  #############################################################################
  # Tests

  describe "older_than/1" do
    test "not old enough" do
      # rule
      rule = older_than(10)

      # torrent
      torrent = torrent(%{added_date: DateTime.utc_now() |> DateTime.add(-9)})

      # too young
      assert match_rule?(rule, torrent) == false
    end

    test "old enough" do
      # rule
      rule = older_than(10)

      # torrent
      torrent = torrent(%{added_date: DateTime.utc_now() |> DateTime.add(-9)})

      # too young
      assert match_rule?(rule, torrent) == false
    end

    test "exact" do
      # rule
      rule = older_than(10)

      # torrent
      torrent = torrent(%{added_date: DateTime.utc_now() |> DateTime.add(-10)})

      # too young
      assert match_rule?(rule, torrent) == false
    end
  end

  describe "minimal_ratio/1" do
    test "too low" do
      # rule
      rule = minimal_ratio(10)

      # torrent
      torrent = torrent(%{upload_ratio: 0.0})

      # too young
      assert match_rule?(rule, torrent) == false
    end

    test "high enough" do
      # rule
      rule = minimal_ratio(10)

      # torrent
      torrent = torrent(%{upload_ratio: 11.0})

      # too young
      assert match_rule?(rule, torrent) == true
    end

    test "exact" do
      # rule
      rule = minimal_ratio(10)

      # torrent
      torrent = torrent(%{upload_ratio: 10.0})

      # too young
      assert match_rule?(rule, torrent) == false
    end
  end

  describe "has_tracker/1" do
    test "has trackers" do
      # rule
      rule = has_tracker(~r/ubuntu\.com/)

      # torrent
      tracker = tracker(%{announce: "https://ubuntu.com/foo"})
      torrent = torrent(%{trackers: [tracker]})

      # too young
      assert match_rule?(rule, torrent) == true
    end

    test "no trackers" do
      # rule
      rule = has_tracker(~r/ubuntu\.com/)

      # torrent
      torrent = torrent(%{trackers: []})

      # too young
      assert match_rule?(rule, torrent) == false
    end

    test "other trackers" do
      # rule
      rule = has_tracker(~r/ubuntu\.com/)

      # torrent
      tracker = tracker(%{announce: "https://foo.com/foo"})
      torrent = torrent(%{trackers: [tracker]})

      # too young
      assert match_rule?(rule, torrent) == false
    end
  end
end
