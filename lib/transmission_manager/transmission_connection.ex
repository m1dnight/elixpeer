defmodule TransmissionManager.TransmissionConnection do
  @moduledoc """
  The connection to the remote transmission instance.

  Keeps a current list of torrents in memory and periodically updates it via the API.
  """
  use GenServer
  alias TransmissionManager.Torrent

  @spec start_link(any(), Keyword.t()) :: {:ok, pid()} | {:error, term()}
  def start_link(_arg, opts \\ []) do
    initial_state = %{
      torrents: [],
      down_speeds: [],
      up_speeds: [],
      current_down_speed: 0.0,
      current_up_speed: 0.0
    }

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

  @spec get_torrents() :: [Torrent.t()]
  def get_torrents do
    GenServer.call(__MODULE__, :torrents)
  end

  @spec force_sync() :: :sync
  def force_sync do
    send(__MODULE__, :sync)
  end

  #############################################################################
  # Helpers

  defp do_sync(state) do
    # update the torrentlist
    new_torrents = get_torrents_from_transmission()

    # update speed stats
    {current_down, current_up} =
      new_torrents
      |> Enum.reduce({0, 0}, fn t, {down, up} -> {down + t.rate_download, up + t.rate_upload} end)

    new_state =
      state
      |> Map.put(:torrents, new_torrents)
      |> Map.update(:down_speeds, [current_down], &Enum.take([current_down | &1], 100))
      |> Map.update(:up_speeds, [current_up], &Enum.take([current_up | &1], 100))
      |> Map.put(:current_up_speed, current_up)
      |> Map.put(:current_down_speed, current_down)

    # broadcast the changed torrentlist
    Phoenix.PubSub.broadcast(
      TransmissionManager.PubSub,
      "torrents",
      {:new_torrents, new_state}
    )

    new_state
  end

  defp get_torrents_from_transmission do
    Transmission.get_torrents()
    |> Enum.map(&Torrent.new/1)
  end

  defp schedule_sync(delay \\ Application.get_env(:transmission_manager, :refresh_rate_ms)) do
    Process.send_after(self(), :scheduled_sync, delay)
  end

  @spec transmission_arguments() :: [String.t()]
  defp transmission_arguments do
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
