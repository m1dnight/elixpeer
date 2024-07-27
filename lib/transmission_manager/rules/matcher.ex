defmodule TransmissionManager.Rules.Matcher do
  alias TransmissionManager.Rules.Rule
  alias TransmissionManager.Rules.RuleSet
  alias TransmissionManager.Torrent

  @spec matches?(Torrent.t(), RuleSet.t() | Rule.t()) :: boolean()
  def matches?(torrent, rule = %RuleSet{}) do
    rule.combinator.(matches?(torrent, rule.left), matches?(torrent, rule.right))
  end

  def matches?(torrent, rule = %Rule{}) do
    torrent_value = Map.get(torrent, rule.field)
    expected_value = rule.value
    rule.operator.(expected_value, torrent_value)
  end
end
