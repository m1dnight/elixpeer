defmodule Elixpeer.TransmissionConnection do
  defstruct torrents: []

  @moduledoc """
  The connection to the remote transmission instance.

  Keeps a current list of torrents in memory and periodically updates it via the API.
  """
  use GenServer

  alias Elixpeer.PubSub
  alias Elixpeer.Torrent
  alias Elixpeer.Torrents

  require Logger

  @spec start_link(any(), Keyword.t()) :: {:ok, pid()} | {:error, term()}
  def start_link(_arg, opts \\ []) do
    initial_state = %__MODULE__{}

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
  # trigger a sync task
  def handle_info(:run_sync, state) do
    Logger.debug("starting new sync task")
    # start a task to run the sync
    Task.start(&do_sync/0)

    {:noreply, state}
  end

  @impl true
  # return the current list of torrents
  def handle_call(:torrents, _from, state) do
    {:reply, state.torrents, state}
  end

  @impl true
  # handle the result from the async task with new torrents
  def handle_cast(:schedule_sync, state) do
    schedule_sync()

    {:noreply, state}
  end

  @impl true
  # handle the result from the async task with new torrents
  def handle_cast({:inserted_torrents, torrents}, state) do
    # broadcast the changed torrentlist
    Phoenix.PubSub.broadcast(PubSub, "torrents", {:new_torrents, torrents})

    {:noreply, %{state | torrents: torrents}}
  end

  def handle_cast(m, state) do
    IO.inspect(m, label: "Unhandled cast")
    {:noreply, state}
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

  # schedules the next sync task
  @spec schedule_sync(integer()) :: :ok
  defp schedule_sync(delay \\ Application.get_env(:elixpeer, :refresh_rate_ms)) do
    if Application.get_env(:elixpeer, :refresh, false) do
      Process.send_after(self(), :run_sync, delay)
    end

    :ok
  end

  # fetches torrents and updates the database
  defp do_sync() do
    # update the torrentlist
    {time, new_torrents} =
      Measure.measure(fn ->
        Transmission.get_torrents()
        |> store_torrents()
      end)

    Logger.debug("inserted all torrents in #{time} seconds")
    # send the torrents back
    GenServer.cast(__MODULE__, {:inserted_torrents, new_torrents})
    GenServer.cast(__MODULE__, :schedule_sync)
  end

  # updates the changes in the database
  @spec store_torrents([map()]) :: [Torrent.t()]
  defp store_torrents(torrent_maps) do
    torrent_maps
    |> Enum.map(fn torrent_map ->
      # convert to a map
      torrent_attrs = Torrents.from_map(torrent_map)

      # insert the trackers
      Torrents.upsert(torrent_attrs)
    end)
  end

  # returns the arguments to connect to transmission
  @spec transmission_arguments() :: [String.t()]
  defp transmission_arguments do
    credentials = Application.get_env(:elixpeer, :credentials, %{})

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
