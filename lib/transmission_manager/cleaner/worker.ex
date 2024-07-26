defmodule TransmissionManager.Cleaner.Worker do
  @moduledoc """
  Worker to periodically clean up torrents.
  """
  use GenServer
  require Logger
  alias TransmissionManager.Torrent

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    schedule_cleanup()
    {:ok, nil}
  end

  def handle_info(:cleanup, state) do
    # do the cleanup
    removed_torrents = TransmissionManager.Cleaner.clean_torrents()

    notify_deleted_torrents(removed_torrents)

    # schedule the next cleanup
    schedule_cleanup()

    {:noreply, state}
  end

  #############################################################################
  # Helpers

  defp schedule_cleanup do
    clean_rate_ms = Application.get_env(:transmission_manager, :clean_rate_ms, 60_000)
    Logger.debug("next cleanup scheduled in #{clean_rate_ms}ms")
    Process.send_after(self(), :cleanup, clean_rate_ms)
  end

  @spec notify_deleted_torrents([Torrent.t()]) :: {:ok, term()} | {:ok, term()}
  defp notify_deleted_torrents([]), do: {:ok, :no_message_sent}

  defp notify_deleted_torrents(torrents) do
    TransmissionManager.Notifier.send_notification(:torrent_deleted, torrents)
  end
end
