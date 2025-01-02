# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule ElixpeerWeb.TorrentsLive do
  use ElixpeerWeb, :live_view

  alias Elixpeer.Torrents
  alias Phoenix.PubSub

  require Logger

  import Elixpeer.TorrentsLive.Torrent
  import ElixpeerWeb.Components.TorrentModal

  def mount(_params, _session, socket) do
    # subscribe for updates on the torrentlist
    PubSub.subscribe(Elixpeer.PubSub, "torrents")

    {:ok,
     assign(socket,
       torrents: [],
       ordering: :active_first,
       modal_content: nil
     )}
  end

  def handle_event("delete_torrent", %{"id" => torrent_id}, socket) do
    Logger.warning("delete torrent #{torrent_id}")

    Transmission.remove_torrent(String.to_integer(torrent_id), true)
    {:noreply, socket}
  catch
    :exit, _ ->
      Logger.warning("Timeout on Transmission.remove_torrent")
      {:noreply, socket}
  end

  def handle_event("pause_torrent", %{"id" => torrent_id}, socket) do
    Logger.warning("pause torrent #{torrent_id}")

    Transmission.stop_torrents(String.to_integer(torrent_id))
    {:noreply, socket}
  catch
    :exit, _ ->
      Logger.warning("Timeout on Transmission.stop_torrents")
      {:noreply, socket}
  end

  def handle_event("start_torrent", %{"id" => torrent_id}, socket) do
    Logger.warning("start torrent #{torrent_id}")

    Transmission.start_torrents(String.to_integer(torrent_id))
    {:noreply, socket}
  catch
    :exit, _ ->
      Logger.warning("Timeout on Transmission.start_torrents")
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

  def handle_event("request_modal_data", %{"torrent_id" => torrent_id}, socket) do
    modal_content = modal_data(torrent_id)

    event_name = "update-torrent-chart-#{torrent_id}"

    socket =
      socket
      |> push_event(event_name, %{data_series: modal_content.data_series})

    {:noreply, socket}
  end

  def handle_event(_event, _value, socket) do
    {:noreply, socket}
  end

  def handle_info({:new_torrents, torrents}, socket) do
    socket =
      socket
      |> assign(torrents: torrents)
      |> apply_ordering()

    {:noreply, socket}
  end

  #############################################################################
  # Helpers

  defp modal_data(torrent_id) do
    torrent = Torrents.get(torrent_id)
    activity = Elixpeer.Statistics.torrent_activities_for(torrent_id)

    upload_data = Enum.map(activity, &[&1.bucket, Decimal.to_float(&1.uploaded)])

    download_data = Enum.map(activity, &[&1.bucket, Decimal.to_float(&1.downloaded)])

    %{
      torrent: torrent,
      data_series: [
        %{name: "Uploaded", data: upload_data},
        %{name: "Downloaded", data: download_data}
      ]
    }
  end

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
          [& &1.added_date, {:asc, NaiveDateTime}]

        :newest_first ->
          [& &1.added_date, {:desc, NaiveDateTime}]

        :uploaded_desc ->
          [& &1.uploaded, :desc]

        :downloaded_desc ->
          [& &1.downloaded, :desc]
      end

    apply(Enum, :sort_by, [torrents | sorter])
  end
end
