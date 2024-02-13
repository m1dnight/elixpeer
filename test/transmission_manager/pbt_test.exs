defmodule TransmissionManager.RulesPBTTest do
  use TransmissionManager.DataCase, async: true
  use PropCheck

  import TransmissionManager.Rules
  import TransmissionManager.Fixtures

  #############################################################################
  # Properties

  property "older_than/1" do
    forall offset <- integer(-1000, -5) do
      # rule
      rule = older_than(5)

      # torrent
      date = DateTime.utc_now() |> DateTime.add(offset, :day)
      torrent = torrent(%{added_date: date})

      # too young
      match_rule?(rule, torrent) == true
    end

    forall offset <- integer(-5, 0) do
      # rule
      rule = older_than(6)

      # torrent
      date = DateTime.utc_now() |> DateTime.add(offset, :day)
      torrent = torrent(%{added_date: date})

      match_rule?(rule, torrent) == false
    end
  end

  #############################################################################
  # Helpers

  #############################################################################
  # Generators
end
