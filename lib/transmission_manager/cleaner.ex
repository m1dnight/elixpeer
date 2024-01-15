defmodule TransmissionManager.Cleaner do
  @moduledoc """
  The cleaner is responsible for cleaning up the torrents.

  Given a set of rules, all torrents that match any of the rules will be deleted.
  """
  alias TransmissionManager.Rule
  alias TransmissionManager.Torrent
  alias TransmissionManager.TransmissionConnection

  require Logger

  @doc """
  Applies all the rules to all torrents and deletes the ones that match any of the rules.
  """
  def clean_torrents() do
    torrents = TransmissionConnection.get_torrents()
    to_delete = matching_torrents(torrents, rules())

    for {torrent, _rules} <- to_delete do
      Logger.info("deleting torrent: #{torrent}")

      if dryrun?() do
        Logger.info("dry run, not deleting torrent")
      else
        Transmission.remove_torrent(torrent.id, true)
      end
    end

    {:ok, to_delete}
  end

  @doc """
  Prints the torrents that match any rule to the console in a pretty format.
  """
  def clean_torrents_pretty() do
    torrents = TransmissionConnection.get_torrents()

    torrents
    |> matching_torrents(rules())
    |> Enum.filter(fn {_, matching_rules} -> matching_rules != [] end)
    |> Enum.map(fn {torrent, matching_rules} ->
      """
      - #{torrent}
        reason: #{Enum.join(matching_rules, "\n")}
      """
    end)
    |> IO.puts()
  end

  @spec match_torrents([Torrent.t()], [Rule.t()]) :: [{Torrent.t(), [Rule.t()]}]
  @doc """
  Given a torrent and a rule, checks if the torrent matches the rules.
  Returns a tuple of the torrent and the rules it matches.
  """
  def match_torrents(torrents, rules) do
    torrents
    |> Enum.map(&match_torrent(&1, rules))
  end

  @spec match_torrent(Torrent.t(), [Rule.t()]) :: {Torrent.t(), [Rule.t()]}
  @doc """
  For a given torrent and a list of rules, returns a tuple of the torrent and the rules that match.
  """
  def match_torrent(torrent, rules) do
    matching_rules =
      rules
      |> Enum.filter(&Rule.match?(&1, torrent))

    {torrent, matching_rules}
  end

  @spec matching_torrents([Torrent.t()], [Rule.t()]) :: [{Torrent.t(), [Rule.t()]}]
  @doc """
  Returns a tuple for each torrent containing the torrent and the rules that matched.
  If no rules matched, no tuple is returned.
  """
  def matching_torrents(torrents, rules) do
    torrents
    |> match_torrents(rules)
    |> Enum.filter(fn {_, matching_rules} -> matching_rules != [] end)
  end

  #############################################################################
  # Helpers

  defp rules do
    [
      %Rule{
        name: "40 days old, seeded for 1+ ratio, inactive for 7 days",
        rule: [
          %Rule{
            name: "older than 40 days",
            rule: fn torrent ->
              cutoff = DateTime.utc_now() |> DateTime.add(40 * -1, :day)
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
              cutoff = DateTime.utc_now() |> DateTime.add(7 * -1, :day)
              DateTime.before?(torrent.activity_date, cutoff)
            end,
            action: :delete,
            enabled: true
          }
        ],
        action: :delete,
        enabled: true
      },
      %Rule{
        name: "downloaded 50 days ago, but never seeded a byte",
        rule: [
          %Rule{
            name: "older than 50 days",
            rule: fn torrent ->
              cutoff = DateTime.utc_now() |> DateTime.add(50 * -1, :day)
              DateTime.before?(torrent.added_date, cutoff)
            end,
            action: :delete,
            enabled: true
          },
          %Rule{
            name: "is complete",
            rule: &(&1.percent_done == 100),
            action: :delete,
            enabled: true
          },
          %Rule{
            name: "did not seed at all",
            rule: fn torrent ->
              torrent.uploaded == 0
            end,
            action: :delete,
            enabled: true
          }
        ],
        action: :delete,
        enabled: true
      }
    ]
  end

  defp dryrun?() do
    Application.get_env(:transmission_manager, :dry_run, true)
  end
end
