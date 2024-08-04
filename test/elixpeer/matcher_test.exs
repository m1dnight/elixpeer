defmodule Elixpeer.RulesTest do
  use Elixpeer.DataCase, async: true

  import Elixpeer.Fixtures
  alias Elixpeer.Rules.Matcher
  alias Elixpeer.Rules.Parser

  describe "matches?" do
    test "older than a day true" do
      # rule
      {:ok, rule} = "age > 1" |> Parser.parse()

      # torrent
      torrent = torrent(%{added_date: DateTime.utc_now() |> DateTime.add(-3, :day)})

      # too young
      assert Matcher.matches?(torrent, rule) == true
    end

    test "older than a day false" do
      # rule
      {:ok, rule} = "age > 1" |> Parser.parse()

      # torrent
      torrent = torrent(%{added_date: DateTime.utc_now()})

      # too young
      assert Matcher.matches?(torrent, rule) == false
    end

    test "younger than a day" do
      # rule
      {:ok, rule} = "age < 1" |> Parser.parse()

      # torrent
      torrent = torrent(%{added_date: DateTime.utc_now()})

      # too young
      assert Matcher.matches?(torrent, rule) == true
    end

    test "ratio > 1" do
      # rule
      {:ok, rule} = "ratio > 1" |> Parser.parse()

      # torrent
      torrent = torrent(%{upload_ratio: 1.1})

      # ratio is greater than 1
      assert Matcher.matches?(torrent, rule) == true
    end

    test "ratio < 1" do
      # rule
      {:ok, rule} = "ratio < 1" |> Parser.parse()

      # torrent
      torrent = torrent(%{upload_ratio: 0.0})

      # ratio is greater than 1
      assert Matcher.matches?(torrent, rule) == true
    end

    test "ratio < 1.23" do
      # rule
      {:ok, rule} = "ratio < 1.23" |> Parser.parse()

      # torrent
      torrent = torrent(%{upload_ratio: 1.22})

      # ratio is greater than 1
      assert Matcher.matches?(torrent, rule) == true
    end

    test "ratio > 1.23" do
      # rule
      {:ok, rule} = "ratio > 1.23" |> Parser.parse()

      # torrent
      torrent = torrent(%{upload_ratio: 1.24})

      # ratio is greater than 1
      assert Matcher.matches?(torrent, rule) == true
    end

    test "tracker regex" do
      # rule
      {:ok, rule} = "tracker ~= /example/" |> Parser.parse()

      # torrent
      tracker = tracker(%{announce: "example"})
      torrent = torrent(%{trackers: [tracker]})

      # ratio is greater than 1
      assert Matcher.matches?(torrent, rule) == true
    end

    test "tracker regex with wildcard" do
      # rule
      {:ok, rule} = "tracker ~= /ex.*/" |> Parser.parse()

      # torrent
      tracker = tracker(%{announce: "example"})
      torrent = torrent(%{trackers: [tracker]})

      # ratio is greater than 1
      assert Matcher.matches?(torrent, rule) == true
    end

    test "tracker regex with escape char" do
      # rule
      {:ok, rule} = "tracker ~= /example\\.com/" |> Parser.parse()

      # torrent
      tracker = tracker(%{announce: "example.com"})
      torrent = torrent(%{trackers: [tracker]})

      # ratio is greater than 1
      assert Matcher.matches?(torrent, rule) == true
    end

    test "tracker regex with escape char false" do
      # rule
      {:ok, rule} = "tracker ~= /example\\.com/" |> Parser.parse()

      # torrent
      tracker = tracker(%{announce: "examplexcom"})
      torrent = torrent(%{trackers: [tracker]})

      # ratio is greater than 1
      assert Matcher.matches?(torrent, rule) == false
    end

    test "tracker exact match" do
      # rule
      {:ok, rule} = "tracker = 'example.com'" |> Parser.parse()

      # torrent
      tracker = tracker(%{announce: "examplexcom"})
      torrent = torrent(%{trackers: [tracker]})

      # ratio is greater than 1
      assert Matcher.matches?(torrent, rule) == false
    end
  end
end
