defmodule TransmissionManager.Cleaner do
  @moduledoc """
  The cleaner is responsible for cleaning up the torrents.

  Given a set of rules, all torrents that match any of the rules will be deleted.
  """
  alias TransmissionManager.Rule
  alias TransmissionManager.TransmissionConnection

  require Logger

  @dry_run Application.compile_env(:transmission_cleaner, :dry_run, true)

  def clean_torrents() do
    torrents = TransmissionConnection.get_torrents()
    to_delete = matching_torrents(torrents, rules())

    for torrent <- to_delete do
      Logger.info("deleting torrent: #{torrent}")

      unless @dry_run do
        Transmission.remove_torrent(torrent.id, true)
      end
    end

    {:ok, to_delete}
  end

  @doc """
  Given a torrent and a rule, checks if the torrent matches the rule.
  """
  def matching_torrents(torrents, rules) do
    torrents
    |> Enum.filter(&matches_rules?(&1, rules))
  end

  def matches_rules?(torrent, rules) do
    rules
    |> Enum.all?(&Rule.match?(&1, torrent))
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
    |> IO.puts()
  end

  # basic rules
  def rules do
    [
      %Rule{
        name: "older than 40 days",
        rule: fn torrent ->
          cutoff = DateTime.utc_now() |> DateTime.add(10 * -1, :day)
          DateTime.before?(torrent.added_date, cutoff)
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
        name: "inactive for 7 days",
        rule: fn torrent ->
          cutoff = DateTime.utc_now() |> DateTime.add(5 * -1, :day)
          DateTime.before?(torrent.activity_date, cutoff)
        end,
        action: :delete,
        enabled: true
      }
    ]
  end
end
