defmodule TransmissionManager.TransmissionConnection do
  @moduledoc """
  The connection to the remote transmission instance.

  Keeps a current list of torrents in memory and periodically updates it via the API.
  """
  use GenServer
  alias TransmissionManager.Torrent

  def start_link(_arg, opts \\ []) do
    initial_state = %{torrents: []}
    GenServer.start_link(__MODULE__, initial_state, opts)
  end

  @impl true
  def init(state) do
    # start the transmission api
    {:ok, _pid} = apply(Transmission, :start_link, transmission_arguments())

    # Schedule work to be performed on start
    schedule_sync(0)

    {:ok, state}
  end

  @impl true
  def handle_info(:sync, state) do
    # update the state and move on
    {:noreply, do_sync(state)}
  end

  @impl true
  def handle_info(:scheduled_sync, state) do
    # update the state
    new_state = do_sync(state)
    # schedule the next update
    schedule_sync()

    # update the state and move on
    {:noreply, new_state}
  end

  @impl true
  def handle_call(:torrents, _from, state) do
    {:reply, state.torrents, state}
  end

  #############################################################################
  # Api

  def get_torrents() do
    GenServer.call(__MODULE__, :torrents)
  end

  def force_sync() do
    send(__MODULE__, :sync)
  end

  #############################################################################
  # Helpers

  defp do_sync(state) do
    # update the torrentlist
    new_torrents = get_torrents_from_transmission()

    # broadcast the changed torrentlist
    Phoenix.PubSub.broadcast(
      TransmissionManager.PubSub,
      "torrents",
      {:new_torrents, new_torrents}
    )

    %{state | torrents: new_torrents}
  end

  defp get_torrents_from_transmission() do
    Transmission.get_torrents()
    |> Enum.map(&Torrent.new/1)
  end

  defp schedule_sync(delay \\ Application.get_env(:transmission_manager, :refresh_rate_ms)) do
    Process.send_after(self(), :scheduled_sync, delay)
  end

  defp transmission_arguments() do
    credentials = Application.get_env(:transmission_manager, :credentials, %{})

    args = [
      credentials.host,
      credentials.username,
      credentials.password
    ]

    args
    |> Enum.each(fn arg ->
      case arg do
        nil -> raise "Missing transmission argument"
        "" -> raise "Missing transmission argument"
        _ -> arg
      end
    end)

    args
  end
end
