defmodule TransmissionManager.Cleaner do
  @moduledoc """
  The cleaner is responsible for cleaning up the torrents.

  Given a set of rules, all torrents that match any of the rules will be deleted.
  """
  alias TransmissionManager.TransmissionConnection
  alias TransmissionManager.Torrent
  alias TransmissionManager.Rule

  require Logger

  import TransmissionManager.Rules

  @doc """
  Applies all the rules to all torrents and deletes the ones that match any of the rules.
  """
  @spec clean_torrents() :: [Torrent.t()]
  def clean_torrents() do
    rule = do_action(rule(), &delete_torrent/1)

    matches = rule_matching_torrents(rule)

    for torrent <- matches do
      Logger.warning("#{torrent} matches rule #{rule}")

      if dryrun?() do
        torrent
      else
        apply_rule(rule, torrent)
      end
    end
  end

  @spec rule_matching_torrents(Rule.t()) :: [TransmissionManager.Torrent.t()]
  def rule_matching_torrents(rule) do
    TransmissionConnection.get_torrents()
    |> Enum.filter(&match_rule?(rule, &1))
  end

  def delete_torrent(torrent) do
    Logger.warning("deleting torrent  '#{torrent.name}' (#{torrent.id})")
    # TransmissionConnection.delete_torrent(torrent)
  end

  defp dryrun?() do
    Application.get_env(:transmission_manager, :dry_run, true)
  end
end
