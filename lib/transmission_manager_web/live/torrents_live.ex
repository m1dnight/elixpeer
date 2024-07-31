# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule TransmissionManagerWeb.TorrentsLive do
  alias TransmissionManager.TransmissionConnection.SpeedStats
  use TransmissionManagerWeb, :live_view
  alias Phoenix.PubSub
  require Logger
  alias TransmissionManager.TorrentsLive.Component

  def mount(_params, _session, socket) do
    # subscribe for updates on the torrentlist
    PubSub.subscribe(TransmissionManager.PubSub, "torrents")
    PubSub.subscribe(TransmissionManager.PubSub, "speed_stats")

    {:ok,
     assign(socket,
       torrents: [],
       ordering: :oldest_first,
       speed_stats: SpeedStats.new()
     )}
  end

  def handle_event("delete_torrent", %{"id" => torrent_id}, socket) do
    Logger.warning("delete torrent #{torrent_id}")
    Transmission.remove_torrent(String.to_integer(torrent_id), true)
    {:noreply, socket}
  end

  def handle_event("pause_torrent", %{"id" => torrent_id}, socket) do
    Logger.warning("pause torrent #{torrent_id}")
    Transmission.stop_torrents(String.to_integer(torrent_id))
    {:noreply, socket}
  end

  def handle_event("start_torrent", %{"id" => torrent_id}, socket) do
    Logger.warning("start torrent #{torrent_id}")
    Transmission.start_torrents(String.to_integer(torrent_id))
    {:noreply, socket}
  end

  def handle_event("order_" <> order, _, socket) do
    order = String.to_existing_atom(order)

    socket =
      socket
      |> assign(:ordering, order)
      |> apply_ordering()

    {:noreply, socket}
  end

  def handle_event(_event, _value, socket) do
    {:noreply, socket}
  end

  def handle_info({:new_torrents, torrents}, socket) do
    # order the torrents
    socket =
      socket
      |> assign(torrents: torrents)
      |> apply_ordering()

    {:noreply, socket}
  end

  def handle_info({:speed_stats, %SpeedStats{} = stats}, socket) do
    {:noreply, assign(socket, speed_stats: stats)}
  end

  #############################################################################
  # Helpers

  # orders the torrents according to the current ordering
  defp apply_ordering(socket) do
    torrents = socket.assigns.torrents
    order = socket.assigns.ordering
    assign(socket, torrents: order_torrents(torrents, order))
  end

  defp order_torrents(torrents, order) do
    sorter =
      case order do
        :ratio_desc ->
          [& &1.upload_ratio, :desc]

        :active_first ->
          [&(&1.rate_download + &1.rate_upload), :desc]

        :oldest_first ->
          [& &1.added_date, {:asc, DateTime}]

        :newest_first ->
          [& &1.added_date, {:desc, DateTime}]
      end

    apply(Enum, :sort_by, [torrents | sorter])
  end
end
