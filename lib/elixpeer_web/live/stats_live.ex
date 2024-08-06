defmodule ElixpeerWeb.StatsLive do
  use ElixpeerWeb, :live_view

  alias Elixpeer.TorrentActivities

  import ElixpeerWeb.Components.Charts

  @spec mount(map(), map(), Phoenix.LiveView.Socket.t()) :: {:ok, Phoenix.LiveView.Socket.t()}
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_async(:activity, fn ->
        {:ok, %{activity: TorrentActivities.torrent_activities()}}
      end)

    {:ok, socket}
  end
end
