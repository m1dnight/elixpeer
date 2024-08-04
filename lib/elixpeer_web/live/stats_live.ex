defmodule ElixpeerWeb.StatsLive do
  use ElixpeerWeb, :live_view

  alias Elixpeer.TorrentActivities

  import ElixpeerWeb.Components.Charts

  @spec mount(map(), map(), Phoenix.LiveView.Socket.t()) :: {:ok, Phoenix.LiveView.Socket.t()}
  def mount(_params, _session, socket) do
    upload_speeds = TorrentActivities.average_speed()
    uploaded = TorrentActivities.volume()

    socket = assign(socket, %{upload_speeds: upload_speeds, uploaded: uploaded})
    {:ok, socket}
  end
end
