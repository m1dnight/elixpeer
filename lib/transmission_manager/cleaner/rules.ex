defmodule TransmissionManager.Rules do
  @moduledoc """
  Defines the basic building blocks for rules to match torrents.
  """
  alias TransmissionManager.Rule
  alias TransmissionManager.Torrent

  require Logger

  #############################################################################
  # Example Rules

  @spec rule() :: TransmissionManager.Rule.t()
  def rule do
    exclude_rutracker()
    |> rule_and(rule_or(old_enough(), seeded_enough()))
  end

  @spec exclude_rutracker() :: TransmissionManager.Rule.t()
  defp exclude_rutracker do
    rule_not(has_tracker(~r/flacsfor\.me/))
  end

  @spec old_enough() :: TransmissionManager.Rule.t()
  defp old_enough do
    older_than(60)
  end

  @spec seeded_enough() :: TransmissionManager.Rule.t()
  defp seeded_enough do
    older_than(40)
    |> rule_and(minimal_ratio(1.0))
    |> rule_and(inactive_for(7))
  end

  #############################################################################
  # Application

  @spec apply_rule(Rule.t(), Torrent.t()) :: Torrent.t()
  def apply_rule(%Rule{action: nil}, torrent) do
    torrent
  end

  def apply_rule(%Rule{action: action}, torrent) do
    action.(torrent)
  end

  #############################################################################
  # Validate

  @spec match_rule?(Rule.t(), Torrent.t()) :: boolean()
  def match_rule?(%Rule{rule: {:or, rule_a, rule_b}}, torrent) do
    match_rule?(rule_a, torrent) or match_rule?(rule_b, torrent)
  end

  def match_rule?(%Rule{rule: {:and, rule_a, rule_b}}, torrent) do
    match_rule?(rule_a, torrent) and match_rule?(rule_b, torrent)
  end

  def match_rule?(%Rule{rule: {:not, rule}}, torrent) do
    not match_rule?(rule, torrent)
  end

  def match_rule?(%Rule{rule: rule}, torrent) do
    rule.(torrent)
  end

  #############################################################################
  # Actions

  def do_action(rule, action) do
    %Rule{
      name: "do action when #{rule.name}",
      rule: rule.rule,
      action: action
    }
  end

  #############################################################################
  # Composition

  @spec rule_and(Rule.t(), Rule.t()) :: Rule.t()
  def rule_and(rule_a, rule_b) do
    label = "#{rule_a.name} and #{rule_b.name}"

    %Rule{
      name: label,
      rule: {:and, rule_a, rule_b}
    }
  end

  @spec rule_or(Rule.t(), Rule.t()) :: Rule.t()
  def rule_or(rule_a, rule_b) do
    label = "#{rule_a.name} or #{rule_b.name}"

    %Rule{
      name: label,
      rule: {:or, rule_a, rule_b}
    }
  end

  @spec rule_not(Rule.t()) :: Rule.t()
  def rule_not(rule) do
    label = "not #{rule.name}"

    %Rule{
      name: label,
      rule: {:not, rule}
    }
  end

  #############################################################################
  # Rules

  @spec older_than(integer()) :: Rule.t()
  def older_than(days) do
    %Rule{
      name: "older than #{days} days",
      rule: fn torrent ->
        cutoff = DateTime.utc_now() |> DateTime.add(days * -1, :day)
        DateTime.before?(torrent.added_date, cutoff)
      end
    }
  end

  @spec minimal_ratio(float()) :: Rule.t()
  def minimal_ratio(ratio) do
    %Rule{
      name: "ratio > #{ratio}",
      rule: fn torrent ->
        torrent.upload_ratio > ratio
      end
    }
  end

  @spec has_tracker(Regex.t()) :: Rule.t()
  def has_tracker(tracker_regex) do
    %Rule{
      name: "tracker #{inspect(tracker_regex)}",
      rule: fn torrent ->
        torrent.trackers
        |> Enum.any?(&Regex.match?(tracker_regex, &1.announce))
      end
    }
  end

  @spec inactive_for(non_neg_integer()) :: TransmissionManager.Rule.t()
  def inactive_for(days) do
    %Rule{
      name: "inactive #{days} days",
      rule: fn torrent ->
        cutoff = DateTime.utc_now() |> DateTime.add(days * -1, :day)
        DateTime.before?(torrent.activity_date, cutoff)
      end
    }
  end

  @spec complete?() :: Rule.t()
  def complete? do
    %Rule{
      name: "complete",
      rule: &(&1.percent_done == 100)
    }
  end

  @spec uploaded_nothing() :: Rule.t()
  def uploaded_nothing do
    %Rule{
      name: "0b upload",
      rule: &(&1.uploaded == 0)
    }
  end

  @spec debug_rule() :: Rule.t()
  def debug_rule do
    %Rule{
      name: "debug",
      rule: fn _ -> true end
    }
  end

  @spec always_false() :: Rule.t()
  def always_false do
    %Rule{
      name: "always false",
      rule: fn _ -> false end
    }
  end

  @spec always_true() :: Rule.t()
  def always_true do
    %Rule{
      name: "always true",
      rule: fn _ -> true end
    }
  end
end
