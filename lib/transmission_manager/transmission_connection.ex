defmodule TransmissionManager.TransmissionConnection do
  @moduledoc """
  The connection to the remote transmission instance.

  Keeps a current list of torrents in memory and periodically updates it via the API.
  """
  use GenServer
  alias TransmissionManager.Torrent

  @refresh_rate_ms Application.compile_env(:transmission_manager, :refresh_rate_ms)
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
    # update the torrentlist
    new_torrents = get_torrents_from_transmission()
    # broadcast the changed torrentlist
    Phoenix.PubSub.broadcast(
      TransmissionManager.PubSub,
      "torrents",
      {:new_torrents, new_torrents}
    )

    # schedule the next update
    schedule_sync()

    # update the state and move on
    new_state = %{state | torrents: new_torrents}
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

  #############################################################################
  # Helpers

  defp get_torrents_from_transmission() do
    Transmission.get_torrents()
    |> Enum.map(&Torrent.new/1)
  end

  defp schedule_sync(delay \\ @refresh_rate_ms) do
    Process.send_after(self(), :sync, delay)
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
