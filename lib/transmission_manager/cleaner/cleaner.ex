defmodule TransmissionManager.Cleaner do
  @moduledoc """
  The cleaner is responsible for cleaning up the torrents.

  Given a set of rules, all torrents that match any of the rules will be deleted.
  """
  alias TransmissionManager.Rules.Matcher
  alias TransmissionManager.Rules.Parser
  alias TransmissionManager.Rules.RuleSet
  alias TransmissionManager.Torrent
  alias TransmissionManager.TransmissionConnection

  require Logger

  @doc """
  Applies all the rules to all torrents and deletes the ones that match any of the rules.
  """
  @spec clean_torrents() :: [Torrent.t()]
  def clean_torrents do
    # read the ruleset from the configuration
    {:ok, ruleset} = ruleset()

    ruleset
    |> matching_torrents()
    |> Enum.map(&delete_torrent/1)
  end

  @spec matching_torrents(RuleSet.t()) :: [TransmissionManager.Torrent.t()]
  def matching_torrents(rule) do
    TransmissionConnection.get_torrents()
    |> Enum.filter(&Matcher.matches?(&1, rule))
  end

  @doc """
  Removes the given torrent from the transmission endpoint.
  """
  @spec delete_torrent(Torrent.t()) :: Torrent.t()
  def delete_torrent(torrent) do
    if dryrun?() do
      Logger.warning("would delete torrent  '#{torrent.name}' (#{torrent.id})")
    else
      Logger.warning("deleting torrent  '#{torrent.name}' (#{torrent.id})")
      Transmission.remove_torrent(torrent.id, true)
    end

    torrent
  end

  #############################################################################
  # Helpers

  @spec dryrun?() :: boolean()
  defp dryrun? do
    Application.get_env(:transmission_manager, :dry_run, true)
  end

  defp ruleset do
    with ruleset <- Application.get_env(:transmission_manager, :ruleset),
         {:ok, ruleset} <- Parser.parse(ruleset) do
      {:ok, ruleset}
    else
      e -> e
    end
  end
end
