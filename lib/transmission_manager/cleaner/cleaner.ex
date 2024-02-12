defmodule TransmissionManager.Cleaner do
  @moduledoc """
  The cleaner is responsible for cleaning up the torrents.

  Given a set of rules, all torrents that match any of the rules will be deleted.
  """
  alias TransmissionManager.TransmissionConnection

  require Logger

  import TransmissionManager.Rules

  @doc """
  Applies all the rules to all torrents and deletes the ones that match any of the rules.
  """
  def clean_torrents() do
    rule = rule()
    matches = rule_matching_torrents(rule)

    for torrent <- matches do
      Logger.warn """
      #{torrent} matches rule #{rule}
      """
      if not dryrun?() do
        apply_rule(rule, torrent, fn _ -> :ok end)
      else
        nil
      end
    end
  end

  def rule_matching_torrents(rule) do
    torrents = TransmissionConnection.get_torrents()

    torrents
    |> Enum.filter(&match_rule?(rule, &1))
  end

  defp dryrun?() do
    Application.get_env(:transmission_manager, :dry_run, true)
  end
end
