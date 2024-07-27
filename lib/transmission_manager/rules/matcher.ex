defmodule TransmissionManager.Rules.Matcher do
  alias TransmissionManager.Rules.Rule
  alias TransmissionManager.Rules.RuleSet
  alias TransmissionManager.Torrent

  @spec matches?(Torrent.t(), RuleSet.t() | Rule.t()) :: boolean()
  def matches?(torrent, rule = %RuleSet{combinator: :and}) do
    matches?(torrent, rule.left) and matches?(torrent, rule.right)
  end

  def matches?(torrent, rule = %RuleSet{combinator: :or}) do
    matches?(torrent, rule.left) or matches?(torrent, rule.right)
  end

  def matches?(torrent, rule = %Rule{operator: :=, field: field, value: value}) do
    Map.get(torrent, field) == value
  end

  def matches?(torrent, rule = %Rule{operator: :>, field: field, value: value}) do
    Map.get(torrent, field) > value
  end

  def matches?(torrent, rule = %RuleSet{combinator: :and}) do
    matches?(torrent, rule.left) and matches?(torrent, rule.right)
  end
end
