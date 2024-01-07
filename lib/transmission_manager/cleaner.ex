defmodule TransmissionManager.Cleaner do
  alias TransmissionManager.Rule
  alias TransmissionManager.Torrent

  @dry_run Application.compile_env(:transmission_cleaner, :dry_run, true)

  @doc """
  Given a torrent and a rule, checks if the torrent matches the rule.
  """
  def matching_torrents(torrents, rules) do
    torrents
    |> Enum.map(fn torrent ->
      matching_rules =
        Enum.filter(rules, fn rule ->
          Rule.match?(rule, torrent)
        end)

      {torrent, matching_rules}
    end)
    |> Enum.filter(fn
      {_, []} -> false
      _ -> true
    end)
  end

  def matching_torrents_pretty(torrents, rules) do
    matching_torrents(torrents, rules)
    |> Enum.map(fn {torrent, matching_rules} ->
      """
      Torrent: #{torrent}
      Rules:
      #{Enum.join(matching_rules, "\n")}
      """
    end)
  end

  # basic rules
  def rules do
    [
      %Rule{
        name: "older than 50 days",
        rule: fn torrent ->
          month_ago = DateTime.utc_now() |> DateTime.add(50 * -1, :day)
          DateTime.before?(torrent.added_date, month_ago)
        end,
        action: :delete,
        enabled: true
      },
      %Rule{
        name: "seeded for 1+ ratio",
        rule: fn torrent ->
          torrent.upload_ratio > 1.0
        end,
        action: :delete,
        enabled: true
      },
      %Rule{
        name: "inactive for 10 days",
        rule: fn torrent ->
          month_ago = DateTime.utc_now() |> DateTime.add(10 * -1, :day)
          DateTime.before?(torrent.activity_date, month_ago)
        end,
        action: :delete,
        enabled: true
      }
    ]
  end
end
