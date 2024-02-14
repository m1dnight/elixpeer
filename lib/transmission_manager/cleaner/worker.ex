defmodule TransmissionManager.Cleaner.Worker do
  @moduledoc """
  Worker to periodically clean up torrents.
  """
  use GenServer
  require Logger


  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  def init(_) do
    schedule_cleanup()
    {:ok, nil}
  end

  def handle_info(:cleanup, state) do
    # do the cleanup
    TransmissionManager.Cleaner.clean_torrents()

    # schedule the next cleanup
    schedule_cleanup()

    {:noreply, state}
  end

  #############################################################################
  # Helpers

  defp schedule_cleanup() do
    clean_rate_ms = Application.get_env(:transmission_manager, :clean_rate_ms, 60_000)
    Logger.warning("next cleanup scheduled in #{clean_rate_ms}ms")
    Process.send_after(self(), :cleanup, clean_rate_ms)
  end
end
