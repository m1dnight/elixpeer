defmodule TransmissionManager.RulesTest do
  use TransmissionManager.DataCase, async: true

  import TransmissionManager.Rules
  import TransmissionManager.Fixtures

  #############################################################################
  # Helpers

  #############################################################################
  # Application

  describe "apply_rule/3" do
    test "delete" do
      # rule
      rule = delete_when(always_true())

      # torrent
      torrent = torrent()

      # action
      test_pid = self()

      action = fn torrent -> send(test_pid, :delete) end

      apply_rule(rule, torrent, action)

      assert_receive(:delete, 1000)
    end

    test "ignore action" do
      # rule
      rule = ignore_when(always_true())

      # torrent
      torrent = torrent(%{name: "dont delete me"})

      # action
      test_pid = self()

      action = fn torrent -> send(test_pid, :not_deleted) end

      apply_rule(rule, torrent, action)

      refute_received(:not_deleted, 1000)
    end
  end

  #############################################################################
  # Composition

  describe "rule_and/2" do
    test "true and false" do
      # rule
      rule_a = always_false()
      rule_b = always_true()
      rule = rule_and(rule_a, rule_b)

      # torrent
      torrent = torrent()

      # too young
      assert match_rule?(rule, torrent) == false
    end

    test "true and true" do
      # rule
      rule_a = always_true()
      rule_b = always_true()
      rule = rule_and(rule_a, rule_b)

      # torrent
      torrent = torrent()

      # too young
      assert match_rule?(rule, torrent) == true
    end

    test "false and false" do
      # rule
      rule_a = always_false()
      rule_b = always_false()
      rule = rule_and(rule_a, rule_b)

      # torrent
      torrent = torrent()

      # too young
      assert match_rule?(rule, torrent) == false
    end
  end

  describe "rule_or/2" do
    test "true or false" do
      # rule
      rule_a = always_false()
      rule_b = always_true()
      rule = rule_or(rule_a, rule_b)

      # torrent
      torrent = torrent()

      # too young
      assert match_rule?(rule, torrent) == true
    end

    test "true or true" do
      # rule
      rule_a = always_true()
      rule_b = always_true()
      rule = rule_or(rule_a, rule_b)

      # torrent
      torrent = torrent()

      # too young
      assert match_rule?(rule, torrent) == true
    end

    test "false or false" do
      # rule
      rule_a = always_false()
      rule_b = always_false()
      rule = rule_or(rule_a, rule_b)

      # torrent
      torrent = torrent()

      # too young
      assert match_rule?(rule, torrent) == false
    end
  end

  describe "rule_not/1" do
    test "not true" do
      # rule
      rule_a = always_true()
      rule = rule_not(rule_a)

      # torrent
      torrent = torrent()

      # too young
      assert match_rule?(rule, torrent) == false
    end

    test "not false" do
      # rule
      rule_a = always_false()
      rule = rule_not(rule_a)

      # torrent
      torrent = torrent()

      # too young
      assert match_rule?(rule, torrent) == true
    end
  end

  #############################################################################
  # Rules

  describe "older_than/1" do
    test "not old enough" do
      # rule
      rule = older_than(10)

      # torrent
      torrent = torrent(%{added_date: DateTime.utc_now() |> DateTime.add(-9, :day)})

      # too young
      assert match_rule?(rule, torrent) == false
    end

    test "old enough" do
      # rule
      rule = older_than(10)

      # torrent
      torrent = torrent(%{added_date: DateTime.utc_now() |> DateTime.add(-9, :day)})

      # too young
      assert match_rule?(rule, torrent) == false
    end

    test "exact" do
      # rule
      rule = older_than(10)

      # torrent
      torrent = torrent(%{added_date: DateTime.utc_now() |> DateTime.add(-10, :day)})

      # too young
      assert match_rule?(rule, torrent) == true
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

  describe "inactive_for/1" do
    test "recently active" do
      # rule
      rule = inactive_for(10)

      # torrent
      torrent = torrent(%{activity_date: DateTime.utc_now() |> DateTime.add(-9, :day)})

      # too young
      assert match_rule?(rule, torrent) == false
    end

    test "inactive" do
      # rule
      rule = inactive_for(10)

      # torrent
      torrent = torrent(%{activity_date: DateTime.utc_now() |> DateTime.add(-11, :day)})

      # inactive long enough
      assert match_rule?(rule, torrent) == true
    end

    test "exact" do
      # rule
      rule = inactive_for(10)

      # torrent
      torrent = torrent(%{activity_date: DateTime.utc_now() |> DateTime.add(-10, :day)})

      # too young
      assert match_rule?(rule, torrent) == true
    end
  end

  describe "is_complete/0" do
    test "not complete" do
      # rule
      rule = is_complete()

      # torrent
      torrent = torrent(%{percent_done: 99.9})

      # too young
      assert match_rule?(rule, torrent) == false
    end

    test "complete" do
      # rule
      rule = is_complete()

      # torrent
      torrent = torrent(%{percent_done: 100.0})

      # too young
      assert match_rule?(rule, torrent) == true
    end
  end

  describe "uploaded_nothing/0" do
    test "uploaded" do
      # rule
      rule = uploaded_nothing()

      # torrent
      torrent = torrent(%{uploaded: 1})

      # too young
      assert match_rule?(rule, torrent) == false
    end

    test "not uploaded" do
      # rule
      rule = uploaded_nothing()

      # torrent
      torrent = torrent(%{uploaded: 0})

      # too young
      assert match_rule?(rule, torrent) == true
    end
  end

  describe "debug_rule/0" do
    test "always matches" do
      # rule
      rule = debug_rule()

      # torrent
      torrent = torrent()

      # too young
      assert match_rule?(rule, torrent) == true
    end
  end
end
