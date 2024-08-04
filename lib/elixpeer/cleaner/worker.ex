defmodule Elixpeer.Cleaner.Worker do
  @moduledoc """
  Worker to periodically clean up torrents.
  """
  use GenServer
  require Logger
  alias Elixpeer.Torrent

  @spec start_link(any()) :: {:ok, pid()} | {:error, term()}
  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    schedule_cleanup()
    {:ok, nil}
  end

  @impl true
  def handle_info(:cleanup, state) do
    # do the cleanup
    removed_torrents = Elixpeer.Cleaner.clean_torrents()

    notify_deleted_torrents(removed_torrents)

    # schedule the next cleanup
    schedule_cleanup()

    {:noreply, state}
  end

  #############################################################################
  # Helpers

  @spec schedule_cleanup() :: :ok
  defp schedule_cleanup do
    clean_rate_ms = Application.get_env(:elixpeer, :clean_rate_ms, 60_000)
    Logger.debug("next cleanup scheduled in #{clean_rate_ms}ms")

    if clean_rate_ms == -1 do
      Logger.warning("cleaning is disabled")
    else
      Process.send_after(self(), :cleanup, clean_rate_ms)
    end

    :ok
  end

  @spec notify_deleted_torrents([Torrent.t()]) :: {:ok, term()} | {:ok, term()}
  defp notify_deleted_torrents([]), do: {:ok, :no_message_sent}

  defp notify_deleted_torrents(torrents) do
    Elixpeer.Notifier.send_notification(:torrent_deleted, torrents)
  end
end
