defmodule TransmissionManagerWeb.TorrentsLive do
  use TransmissionManagerWeb, :live_view
  alias Phoenix.PubSub
  require Logger
  alias TransmissionManager.TorrentsLive.Component

  def mount(_params, _session, socket) do
    # subscribe for updates on the torrentlist
    PubSub.subscribe(TransmissionManager.PubSub, "torrents")

    {:ok, assign(socket, torrents: [], ordering: :oldest_first)}
  end

  @spec render(assigns :: map) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <!-- Menu -->
    <div class="flex ">
      <div class="flex items-center me-4">
        <input
          checked={@ordering == :newest_first}
          id="inline-radio"
          type="radio"
          value="order_newest_first"
          name="inline-radio-group"
          phx-click="order_newest_first"
          class="w-4 h-4 text-blue-600 bg-gray-100 border-gray-300 focus:ring-blue-500 dark:focus:ring-blue-600 dark:ring-offset-gray-800 focus:ring-2 dark:bg-gray-700 dark:border-gray-600"
        />
        <label for="inline-radio" class="ms-2 text-sm font-medium ">
          Newest first
        </label>
      </div>
      <div class="flex items-center me-4">
        <input
          checked={@ordering == :oldest_first}
          id="inline-2-radio"
          type="radio"
          value="order_oldest_first"
          name="inline-radio-group"
          phx-click="order_oldest_first"
          class="w-4 h-4 text-blue-600 bg-gray-100 border-gray-300 focus:ring-blue-500 dark:focus:ring-blue-600 dark:ring-offset-gray-800 focus:ring-2 dark:bg-gray-700 dark:border-gray-600"
        />
        <label for="inline-2-radio" class="ms-2 text-sm font-medium">
          Oldest First
        </label>
      </div>
      <div class="flex items-center me-4">
        <input
          checked={@ordering == :active_first}
          id="inline-radio"
          type="radio"
          value="order_active_first"
          name="inline-radio-group"
          phx-click="order_active_first"
          class="w-4 h-4 text-blue-600 bg-gray-100 border-gray-300 focus:ring-blue-500 dark:focus:ring-blue-600 dark:ring-offset-gray-800 focus:ring-2 dark:bg-gray-700 dark:border-gray-600"
        />
        <label for="inline-radio" class="ms-2 text-sm font-medium ">
          Active First
        </label>
      </div>
      <div class="flex items-center me-4">
        <input
          checked={@ordering == :ratio_desc}
          id="inline-radio"
          type="radio"
          value="order_active_first"
          name="inline-radio-group"
          phx-click="order_ratio_desc"
          class="w-4 h-4 text-blue-600 bg-gray-100 border-gray-300 focus:ring-blue-500 dark:focus:ring-blue-600 dark:ring-offset-gray-800 focus:ring-2 dark:bg-gray-700 dark:border-gray-600"
        />
        <label for="inline-radio" class="ms-2 text-sm font-medium ">
          Sort by ratio
        </label>
      </div>
    </div>
    <!-- Torrentlist -->
    <div class="grid grid-cols-1 gap-1">
      <%= for t <- @torrents do %>
        <Component.torrent torrent={t} />
      <% end %>
    </div>
    """
  end

  def handle_event("delete_torrent", %{"id" => torrent_id}, socket) do
    Logger.warning("delete torrent #{torrent_id}")
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

  def handle_info({:new_torrents, new_torrents}, socket) do
    # order the torrents
    socket =
      socket
      |> assign(:torrents, new_torrents)
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
