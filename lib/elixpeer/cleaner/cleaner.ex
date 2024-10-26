defmodule Elixpeer.Cleaner do
  @moduledoc """
  The cleaner is responsible for cleaning up the torrents.

  Given a set of rules, all torrents that match any of the rules will be deleted.
  """
  alias Elixpeer.Rules.Matcher
  alias Elixpeer.Rules.Parser
  alias Elixpeer.Rules.RuleSet
  alias Elixpeer.Torrent
  alias Elixpeer.TransmissionConnection

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
    |> Enum.filter(&(&1 != nil))
  end

  @spec matching_torrents(RuleSet.t()) :: [Elixpeer.Torrent.t()]
  def matching_torrents(rule) do
    TransmissionConnection.get_torrents(forced: true)
    |> Enum.filter(&Matcher.matches?(&1, rule))
  end

  @doc """
  Removes the given torrent from the transmission endpoint.
  """
  @spec delete_torrent(Torrent.t()) :: Torrent.t()
  def delete_torrent(torrent) do
    if dryrun?() do
      Logger.warning("would delete torrent  '#{torrent.name}' (#{torrent.id})")
      nil
    else
      Logger.warning("deleting torrent  '#{torrent.name}' (#{torrent.id})")
      Transmission.remove_torrent(torrent.id, true)
      torrent
    end
  end

  #############################################################################
  # Helpers

  @spec dryrun?() :: boolean()
  defp dryrun? do
    Application.get_env(:elixpeer, :dry_run, true)
  end

  @spec ruleset() :: {:ok, RuleSet.t()} | {:error, any()}
  defp ruleset do
    with ruleset <- Application.get_env(:elixpeer, :ruleset),
         {:ok, ruleset} <- Parser.parse(ruleset) do
      {:ok, ruleset}
    else
      e -> e
    end
  end
end
