defmodule ElixpeerWeb.StatsLive do
  use ElixpeerWeb, :live_view

  alias Elixpeer.TorrentActivities

  import ElixpeerWeb.Components.Charts

  @spec mount(map(), map(), Phoenix.LiveView.Socket.t()) :: {:ok, Phoenix.LiveView.Socket.t()}
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_async(:upload_speeds, fn ->
        {:ok, %{upload_speeds: TorrentActivities.average_speed()}}
      end)
      |> assign_async(:uploaded, fn -> {:ok, %{uploaded: TorrentActivities.volume()}} end)

    {:ok, socket}
  end
end
