defmodule TransmissionManager.TransmissionConnection.SpeedStats do
  @moduledoc """
  Contains the in-memory statistics for transmission speeds.
  """
  @type t :: %__MODULE__{
          :upload_speeds_buckets => %{
            DateTime.t() => %{mean: float(), count: integer(), sum: float()}
          },
          :download_speeds_buckets => %{
            DateTime.t() => %{mean: float(), count: integer(), sum: float()}
          },
          :current_download_speed => float(),
          :current_upload_speed => float(),
          :datapoint_limit => integer()
        }

  defstruct upload_speeds_buckets: %{},
            download_speeds_buckets: %{},
            current_download_speed: 0.0,
            current_upload_speed: 0.0,
            maximum_upload_speed: 0.0,
            datapoint_limit: 172_800

  @spec new :: t()
  def new do
    %__MODULE__{}
  end

  @spec push_upload_speed(t(), float(), DateTime.t()) :: t()
  def push_upload_speed(speed_stats, upload_speed, timestamp) do
    # update the buckets
    upload_speed_buckets =
      speed_stats.upload_speeds_buckets
      |> Map.update(
        bucket(timestamp),
        %{mean: upload_speed, count: 1, sum: upload_speed},
        &%{
          mean: (&1.sum + upload_speed) / (&1.count + 1),
          count: &1.count + 1,
          sum: &1.sum + upload_speed
        }
      )

    Map.put(speed_stats, :upload_speeds_buckets, upload_speed_buckets)
  end

  @spec push_download_speed(t(), float(), DateTime.t()) :: t()
  def push_download_speed(speed_stats, download_speed, timestamp) do
    # update the buckets
    download_speed_buckets =
      speed_stats.download_speeds_buckets
      |> Map.update(
        bucket(timestamp),
        %{mean: download_speed, count: 1, sum: download_speed},
        &%{
          mean: (&1.sum + download_speed) / (&1.count + 1),
          count: &1.count + 1,
          sum: &1.sum + download_speed
        }
      )

    Map.put(speed_stats, :download_speeds_buckets, download_speed_buckets)
  end

  @spec set_current_upload_speed(t(), float()) :: t()
  def set_current_upload_speed(speed_stats, upload_speed) do
    Map.put(speed_stats, :current_upload_speed, upload_speed)
  end

  @spec set_current_download_speed(t(), float()) :: t()
  def set_current_download_speed(speed_stats, download_speed) do
    Map.put(speed_stats, :current_download_speed, download_speed)
  end

  defp bucket(datetime) do
    Map.merge(datetime, %{minute: 0, second: 0, microsecond: {0, 0}})
  end
end

defmodule TransmissionManager.TransmissionConnection do
  @moduledoc """
  The connection to the remote transmission instance.

  Keeps a current list of torrents in memory and periodically updates it via the API.
  """
  use GenServer

  alias TransmissionManager.PubSub
  alias TransmissionManager.Torrent
  alias TransmissionManager.TransmissionConnection.SpeedStats

  require Logger

  @spec start_link(any(), Keyword.t()) :: {:ok, pid()} | {:error, term()}
  def start_link(_arg, opts \\ []) do
    initial_state = %{
      torrents: [],
      speed_stats: SpeedStats.new()
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

    # update the speed statistics
    {current_down, current_up} =
      new_torrents
      |> Enum.reduce({0, 0}, fn t, {down, up} -> {down + t.rate_download, up + t.rate_upload} end)

    timestamp = DateTime.utc_now()

    speed_stats =
      state.speed_stats
      |> SpeedStats.push_download_speed(current_down, timestamp)
      |> SpeedStats.push_upload_speed(current_up, timestamp)
      |> SpeedStats.set_current_download_speed(current_down)
      |> SpeedStats.set_current_upload_speed(current_up)

    # broadcast the changed torrentlist
    Phoenix.PubSub.broadcast(PubSub, "torrents", {:new_torrents, new_torrents})
    Phoenix.PubSub.broadcast(PubSub, "speed_stats", {:speed_stats, speed_stats})

    state
    |> Map.put(:torrents, new_torrents)
    |> Map.put(:speed_stats, speed_stats)
  end

  defp get_torrents_from_transmission do
    Enum.map(Transmission.get_torrents(), &Torrent.new/1)
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
