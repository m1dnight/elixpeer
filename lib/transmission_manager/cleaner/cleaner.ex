defmodule TransmissionManager.Cleaner do
  @moduledoc """
  The cleaner is responsible for cleaning up the torrents.

  Given a set of rules, all torrents that match any of the rules will be deleted.
  """
  alias TransmissionManager.Rule
  alias TransmissionManager.Torrent
  alias TransmissionManager.TransmissionConnection
  alias TransmissionManager.Notifier

  require Logger

  import TransmissionManager.Rules

  @doc """
  Applies all the rules to all torrents and deletes the ones that match any of the rules.
  """
  @spec clean_torrents() :: [Torrent.t()]
  def clean_torrents do
    rule = do_action(debug_rule(), &delete_torrent/1)
    # rule = do_action(rule(), &delete_torrent/1)

    matches = rule_matching_torrents(rule)

    deleted_torrents =
      for torrent <- matches do
        Logger.warning("#{torrent} match:\n#{rule}")

        if dryrun?() do
          torrent
        else
          apply_rule(rule, torrent)
        end
      end

    # force refresh the torrents from the server
    TransmissionConnection.force_sync()

    deleted_torrents
  end

  @spec rule_matching_torrents(Rule.t()) :: [TransmissionManager.Torrent.t()]
  def rule_matching_torrents(rule) do
    TransmissionConnection.get_torrents()
    |> Enum.filter(&match_rule?(rule, &1))
  end

  @spec delete_torrent(Torrent.t()) :: Torrent.t()
  def delete_torrent(torrent) do
    Logger.warning("deleting torrent  '#{torrent.name}' (#{torrent.id})")
    Transmission.remove_torrent(torrent.id, true)
    torrent
  end

  @spec dryrun?() :: boolean()
  defp dryrun? do
    Application.get_env(:transmission_manager, :dry_run, true)
  end
end
