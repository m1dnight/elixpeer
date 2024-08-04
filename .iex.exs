alias Elixpeer.Rule
alias Elixpeer.Torrent
alias Elixpeer.Cleaner
alias Elixpeer.TransmissionConnection
alias Elixpeer.TorrentActivities
alias Elixpeer.TorrentActivity

import Ecto.Query

torrent_map = %{
  error: 0,
  id: 1,
  name: "PD.True.S01E08.1080p.WEB.H264-BUSSY",
  status: 6,
  addedDate: 1_722_112_743,
  downloadedEver: 1_725_303_631,
  isFinished: false,
  percentDone: 1,
  rateDownload: 0,
  rateUpload: 0,
  sizeWhenDone: 1_725_303_631,
  uploadRatio: 0.2591,
  uploadedEver: 447_100_104,
  activityDate: 1_722_630_135,
  trackers: [
    %{
      id: 0,
      announce: "https://tracker.torrentleech.org/a/952d8aa3839094775edb93effdc7f0ae/announce",
      scrape: "https://tracker.torrentleech.org/a/952d8aa3839094775edb93effdc7f0ae/scrape",
      tier: 0,
      sitename: "torrentleech"
    },
    %{
      id: 1,
      announce: "https://tracker.tleechreload.org/a/952d8aa3839094775edb93effdc7f0ae/announce",
      scrape: "https://tracker.tleechreload.org/a/952d8aa3839094775edb93effdc7f0ae/scrape",
      tier: 0,
      sitename: "tleechreload"
    }
  ],
  downloadDir: "/downloads/complete_tmp",
  errorString: "",
  eta: -1,
  haveUnchecked: 0,
  haveValid: 1_725_303_631,
  leftUntilDone: 0,
  seedRatioMode: 0
}
