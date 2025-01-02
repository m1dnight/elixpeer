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
    # Schedule work to be performed on start
    schedule_sync(0)

    {:ok, state}
  end

  @impl true
  # trigger a sync task
  def handle_info(:run_sync, state) do
    Logger.debug("starting new sync task")

    # start a task to run the sync, but do not link
    # if the task fails just let it fail
    Task.start_link(&do_sync/0)

    {:noreply, state}
  end

  @impl true
  # return the current list of torrents
  def handle_call({:torrents, forced: forced?}, _from, state) do
    if forced? do
      {:reply, store_torrents(), state}
    else
      {:reply, state.torrents, state}
    end
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

    # schedule the next sync
    schedule_sync()

    {:noreply, %{state | torrents: torrents}}
  end

  #############################################################################
  # Api

  @spec get_torrents(Keyword.t()) :: [Torrent.t()]
  def get_torrents(opts \\ [forced: false]) do
    forced? = Keyword.get(opts, :forced, false)
    GenServer.call(__MODULE__, {:torrents, forced: forced?}, 60_000)
  end

  @spec force_sync() :: :sync
  def force_sync do
    send(__MODULE__, :sync)
  end

  #############################################################################
  # Helpers

  # @doc """
  # Fetches the torrents from the transmission instance
  # """
  @spec fetch_torrents() :: [map()]
  def fetch_torrents do
    Transmission.get_torrents()
  catch
    :exit, _ -> []
  end

  # @doc """
  # Fetches the torrents from the instance, and stores them in the database.
  # Returns a list of %Torrent{} structs
  # """
  @spec store_torrents() :: [Torrent.t()]
  def store_torrents do
    fetch_torrents()
    |> store_torrents()
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

  # schedules the next sync task
  @spec schedule_sync(integer()) :: :ok
  defp schedule_sync(delay \\ Application.get_env(:elixpeer, :refresh_rate_ms)) do
    if Application.get_env(:elixpeer, :refresh, false) do
      Process.send_after(self(), :run_sync, delay)
    end

    :ok
  end

  # @doc """
  # Fetches torrents and updates the database
  # and replies with the new torrents.
  # """
  defp do_sync do
    # update the torrentlist
    {time, new_torrents} = Measure.measure(&store_torrents/0)

    Logger.debug("inserted all torrents in #{time} seconds")

    # send the torrents back
    GenServer.cast(__MODULE__, {:inserted_torrents, new_torrents})
  end
end
