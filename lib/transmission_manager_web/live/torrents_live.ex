# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule TransmissionManagerWeb.TorrentsLive do
  use TransmissionManagerWeb, :live_view
  alias Phoenix.PubSub
  require Logger
  alias TransmissionManager.TorrentsLive.Component

  def mount(_params, _session, socket) do
    # subscribe for updates on the torrentlist
    PubSub.subscribe(TransmissionManager.PubSub, "torrents")

    {:ok,
     assign(socket,
       torrents: [],
       ordering: :oldest_first,
       down_speeds: [],
       up_speeds: [],
       current_down_speed: 0.0,
       current_up_speed: 0.0
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
    order =
      order
      |> String.to_existing_atom()

    socket =
      socket
      |> assign(:ordering, order)
      |> apply_ordering()

    {:noreply, socket}
  end

  def handle_event(event, value, socket) do
    IO.puts("event: #{inspect(event)} #{inspect(value)} ")
    {:noreply, socket}
  end

  @spec handle_info({:new_torrents, %{:torrents => any(), optional(any()) => any()}}, map()) ::
          {:noreply, any()}
  def handle_info({:new_torrents, new_state}, socket) do
    # order the torrents
    Logger.debug("Torrents update: #{inspect(Map.drop(new_state, [:torrents]))}")

    socket =
      socket
      |> assign(new_state)
      |> apply_ordering()

    {:noreply, socket}
  end

  #############################################################################
  # Helpers

  defp apply_ordering(socket) do
    torrents = socket.assigns.torrents
    order = socket.assigns.ordering

    torrents = order_torrents(torrents, order)

    socket = assign(socket, torrents: torrents)

    socket
  end

  defp order_torrents(torrents, :ratio_desc) do
    torrents
    |> Enum.sort_by(& &1.upload_ratio, :desc)
  end

  defp order_torrents(torrents, :active_first) do
    torrents
    |> Enum.sort_by(&(&1.rate_download + &1.rate_upload), :desc)
  end

  defp order_torrents(torrents, :oldest_first) do
    torrents
    |> Enum.sort_by(& &1.added_date, {:asc, DateTime})
  end

  defp order_torrents(torrents, :newest_first) do
    torrents
    |> Enum.sort_by(& &1.added_date, {:desc, DateTime})
  end

  defp order_torrents(torrents, _), do: torrents
end
