defmodule ElixpeerWeb.StatsLive do
  use ElixpeerWeb, :live_view

  alias Elixpeer.Statistics
  alias Phoenix.LiveView.AsyncResult

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:activity, AsyncResult.loading())
      |> start_async(:activity, fn -> Statistics.torrent_activities() end)

    # |> assign_async(:activity, fn ->
    #   {:ok, %{activity: Statistics.torrent_activities()}}
    # end)

    {:ok, socket}
  end

  @impl true
  def handle_async(:activity, {:exit, reason}, socket) do
    Logger.error("failed to get stats: #{inspect(reason)}")
    {:noreply, socket}
  end

  def handle_async(:activity, {:ok, data}, socket) do
    downloaded_data = %{
      name: "Downloaded",
      data: Enum.map(data, &[&1.bucket, Decimal.to_float(&1.downloaded)])
    }

    uploaded_data = %{
      name: "Uploaded",
      data: Enum.map(data, &[&1.bucket, Decimal.to_float(&1.uploaded)])
    }

    upload_data = %{
      name: "Upload",
      data: Enum.map(data, &[&1.bucket, Decimal.to_float(&1.upload_speed_bps)])
    }

    download_data = %{
      name: "Download",
      data: Enum.map(data, &[&1.bucket, Decimal.to_float(&1.download_speed_bps)])
    }

    socket =
      socket
      |> assign(:activity, AsyncResult.ok(nil))
      |> push_event("update-speed-chart", %{data_series: [download_data, upload_data]})
      |> push_event("update-volume-chart", %{data_series: [downloaded_data, uploaded_data]})

    {:noreply, socket}
  end
end
