# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule TransmissionManager.TorrentsLive.Component do
  use Phoenix.Component

  # %{
  #   error: 0,
  #   id: 161,
  #   name: "Monarch.Legacy.of.Monsters.S01E09.2160p.WEB.H265-NHTFS",
  #   status: 6,
  #   addedDate: 1_704_421_573,
  #   trackers: [
  #     %{
  #       id: 304,
  #       announce: "https://tracker.torrentleech.org/a/952d8aa3839094775edb93effdc7f0ae/announce",
  #       scrape: "https://tracker.torrentleech.org/a/952d8aa3839094775edb93effdc7f0ae/scrape",
  #       sitename: "torrentleech",
  #       tier: 0
  #     },
  #     %{
  #       id: 305,
  #       announce: "https://tracker.tleechreload.org/a/952d8aa3839094775edb93effdc7f0ae/announce",
  #       scrape: "https://tracker.tleechreload.org/a/952d8aa3839094775edb93effdc7f0ae/scrape",
  #       sitename: "tleechreload",
  #       tier: 0
  #     }
  #   ],
  #   downloadDir: "/downloads/complete",
  #   downloadedEver: 7_344_812_516,
  #   errorString: "",
  #   eta: -1,
  #   haveUnchecked: 0,
  #   haveValid: 7_344_812_516,
  #   isFinished: false,
  #   leftUntilDone: 0,
  #   percentDone: 1,
  #   rateDownload: 0,
  #   rateUpload: 32000,
  #   seedRatioMode: 0,
  #   sizeWhenDone: 7_344_812_516,
  #   uploadRatio: 0.1677,
  #   uploadedEver: 1_231_584_715
  # }

  def summary(assigns) do
    ~H"""
    <div class="grid grid-cols-4 gap-1">
      <button class="">
        🧮 <%= @torrent_count %> torrents
      </button>
      <button class="">
        🌱 <%= @seeded_torrents %> seeded
      </button>
      <button class="">
        💾 <%= @total_size |> Size.humanize!() %>
      </button>
      <button class="">
        📈 <%= @total_uploaded |> Size.humanize!() %> | 📉 <%= @total_downloaded |> Size.humanize!() %>
      </button>
    </div>
    """
  end

  def chart(assigns) do
    # parameters = %{columns = 10
    # width = 300
    # height = 100
    # col_width = width / columns
    # max_speed = max(1.0, Enum.max(assigns.speed.up, fn -> 0.0 end))}

    max_speed_up = Enum.max(assigns.up_speeds, fn -> 0.0 end)
    max_speed_down = Enum.max(assigns.down_speeds, fn -> 0.0 end)

    height = 50
    width = 300
    columns = 100
    column_width = width / columns

    params = %{
      height: height,
      width: width,
      columns: columns,
      column_width: column_width,
      height_factor_down: height / max(1.0, max_speed_down),
      height_factor_up: height / max(1.0, max_speed_up),
      max_up_speed: max_speed_up,
      max_down_speed: max_speed_down
    }

    assigns = assign(assigns, params)

    ~H"""
    <div class="flex flex-row">
      <div class="svg-container basis-1/1">
        <svg xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox={"0 0 #{@width} #{@height}"}>
          <rect
            :for={{speed, col} <- Enum.with_index(@up_speeds)}
            x={col * @column_width}
            y={1 + @height - speed * @height_factor_up}
            width={@column_width}
            height={speed * @height_factor_up}
            fill="green"
            fill-opacity="0.5"
          />
          <rect
            :for={{speed, col} <- Enum.with_index(@down_speeds)}
            x={col * @column_width}
            y={@height - speed * @height_factor_down}
            width={@column_width}
            height={speed * @height_factor_down}
            fill="red"
            fill-opacity="1"
          />
        </svg>
      </div>
    </div>
    """
  end

  def torrent(assigns) do
    ~H"""
    <!-- Title and size -->
    <div class="flex flex-row">
      <div class="basis-3/4 text-left font-semibold">
        <%= @torrent.name %>
      </div>
      <div class="basis-1/4 text-right font-light">
        <%= Float.round(@torrent.size_when_done / :math.pow(1000, 3), 2) %> GB
      </div>
    </div>
    <!--  Age -->
    <div class="flex flex-row">
      <div class="text-left font-light">
        <!-- Speed -->
        <span class="bg-blue-100 text-sm font-medium me-2 px-2.5 py-0.5 rounded dark:bg-blue-900 ">
          <%= if @torrent.rate_download > 0,
            do: "#{@torrent.rate_download |> trunc |> Size.humanize!(bits: true)}/s",
            else: "--" %> | <%= if @torrent.rate_upload > 0,
            do: "#{@torrent.rate_upload |> trunc |> Size.humanize!(bits: true)}/s",
            else: "--" %>
        </span>
        <!-- Age -->
        <span class="bg-blue-100 text-sm font-medium me-2 px-2.5 py-0.5 rounded dark:bg-blue-900">
          <%= Calendar.strftime(@torrent.added_date, "%x") %> (<%= Date.diff(
            DateTime.utc_now(),
            @torrent.added_date
          ) %> days)
        </span>
        <!-- Ratio  and actions-->
        <span class="bg-blue-100 text-sm font-medium me-2 px-2.5 py-0.5 rounded dark:bg-blue-900 ">
          <%= Size.humanize!(@torrent.size_when_done) %>
        </span>
        <!-- Ratio  and actions-->
        <span class="bg-blue-100 text-sm font-medium me-2 px-2.5 py-0.5 rounded dark:bg-blue-900 ">
          <%= Float.round(@torrent.upload_ratio, 2) %>
        </span>
      </div>

      <div class="grow text-right font-light">
        <!-- Trash -->
        <button phx-click="delete_torrent" phx-value-id={@torrent.id} data-confirm="Are you sure?">
          <svg
            class="w-4 h-4 text-red-800 dark:text-red-400"
            aria-hidden="true"
            xmlns="http://www.w3.org/2000/svg"
            fill="currentColor"
            viewBox="0 0 18 20"
          >
            <path d="M17 4h-4V2a2 2 0 0 0-2-2H7a2 2 0 0 0-2 2v2H1a1 1 0 0 0 0 2h1v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V6h1a1 1 0 1 0 0-2ZM7 2h4v2H7V2Zm1 14a1 1 0 1 1-2 0V8a1 1 0 0 1 2 0v8Zm4 0a1 1 0 0 1-2 0V8a1 1 0 0 1 2 0v8Z" />
          </svg>
        </button>
        <!-- Pause -->
        <button
          :if={@torrent.status not in [:stopped]}
          phx-click="pause_torrent"
          phx-value-id={@torrent.id}
        >
          <svg
            class="w-4 h-4 text-red-800 dark:text-red-400"
            aria-hidden="true"
            xmlns="http://www.w3.org/2000/svg"
            fill="currentColor"
            viewBox="0 0 10 16"
          >
            <path
              fill-rule="evenodd"
              d="M0 .8C0 .358.32 0 .714 0h1.429c.394 0 .714.358.714.8v14.4c0 .442-.32.8-.714.8H.714a.678.678 0 0 1-.505-.234A.851.851 0 0 1 0 15.2V.8Zm7.143 0c0-.442.32-.8.714-.8h1.429c.19 0 .37.084.505.234.134.15.209.354.209.566v14.4c0 .442-.32.8-.714.8H7.857c-.394 0-.714-.358-.714-.8V.8Z"
              clip-rule="evenodd"
            />
          </svg>
        </button>
        <!-- Play -->
        <button :if={@torrent.status == :stopped} phx-click="start_torrent" phx-value-id={@torrent.id}>
          <svg
            class="w-4 h-4"
            aria-hidden="true"
            xmlns="http://www.w3.org/2000/svg"
            fill="currentColor"
            viewBox="0 0 14 16"
          >
            <path d="M0 .984v14.032a1 1 0 0 0 1.506.845l12.006-7.016a.974.974 0 0 0 0-1.69L1.506.139A1 1 0 0 0 0 .984Z" />
          </svg>
        </button>
      </div>
    </div>
    <div class="flex flex-row">
      <div class="w-full bg-gray-200 rounded-full h-2.5 dark:bg-gray-700">
        <div class="bg-blue-600 h-2.5 rounded-full" style={"width: #{@torrent.percent_done}%;"}></div>
      </div>
    </div>
    """
  end
end
