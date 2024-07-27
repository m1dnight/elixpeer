defmodule TransmissionManager.Fixtures do
  @moduledoc """
  Fixtures to generate entities during testing.
  """
  alias TransmissionManager.Torrent
  alias TransmissionManager.Tracker
  @spec torrent(map()) :: Torrent.t()
  def torrent(args \\ %{}) do
    args =
      %{
        id: 1,
        name: "torrent1",
        added_date: DateTime.utc_now() |> DateTime.add(-9),
        activity_date: DateTime.utc_now(),
        is_finished: false,
        rate_download: 1.0,
        rate_upload: 1.0,
        size_when_done: 0,
        upload_ratio: 0.0,
        uploaded: 0,
        downloaded: 0,
        status: 1,
        trackers: [],
        percent_done: 0.0
      }
      |> Map.merge(args)

    struct(Torrent, args)
  end

  @spec tracker(map()) :: Tracker.t()
  def tracker(args \\ %{}) do
    args =
      %{
        id: 1,
        announce: "https://tracker.ubuntu.com/a/announce",
        scrape: "https://tracker.ubuntu.com/a/scrape",
        tier: 0,
        sitename: "ubuntu.com"
      }
      |> Map.merge(args)

    struct(Tracker, args)
  end
end
