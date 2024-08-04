defmodule Elixpeer.Rules.Matcher do
  @moduledoc """
  Contains logic to match torrents against rules.
  """
  alias Elixpeer.Rules.Parser
  alias Elixpeer.Rules.Rule
  alias Elixpeer.Rules.RuleSet
  alias Elixpeer.Torrent

  require Kernel
  @spec matches?(Torrent.t(), RuleSet.t() | Rule.t()) :: boolean()
  def matches?(torrent, rule = %RuleSet{}) do
    {mod, func} = rule.combinator

    apply(mod, func, [matches?(torrent, rule.left), matches?(torrent, rule.right)])
  end

  # Age
  def matches?(torrent, rule = %Rule{field: :age}) do
    {mod, func} = rule.operator
    age_in_days = NaiveDateTime.diff(NaiveDateTime.utc_now(), torrent.added_date, :day)
    apply(mod, func, [age_in_days, rule.value])
  end

  # Ratio
  def matches?(torrent, rule = %Rule{field: :ratio}) do
    {mod, func} = rule.operator
    apply(mod, func, [torrent.upload_ratio, rule.value])
  end

  # Trackers
  def matches?(torrent, rule = %Rule{field: :tracker, operator: {Regex, :match?}}) do
    torrent.trackers
    |> Enum.any?(&Regex.match?(rule.value, &1.announce))
  end

  def matches?(torrent, rule = %Rule{field: :tracker, operator: {Parser, :not_match?}}) do
    torrent.trackers
    |> Enum.all?(&Parser.not_match?(rule.value, &1.announce))
  end

  def matches?(torrent, rule = %Rule{field: :tracker, operator: {Kernel, :==}}) do
    torrent.trackers
    |> Enum.any?(&(rule.value == &1.announce))
  end
end
