# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Elixpeer.TorrentsLive.Component do
  use Phoenix.Component

  use ElixpeerWeb, :live_view

  import ElixpeerWeb.Components.Charts
  import ElixpeerWeb.Components.Pills

  def torrent_modal(assigns) do
    ~H"""
    <.modal id="user-modal" show={true}>
      <%= if @modal_content == nil do %>
        <p>Nothing to see here</p>
      <% else %>
        <div>
          <!-- Title -->
          <div class="flex flex-row mb-4">
            <div class="basis-full text-center text-xl">
              <%= @modal_content.torrent.name %>
            </div>
          </div>
          <!-- pills -->
          <div class="flex flex-row justify-center">
            <.pill :if={@modal_content.torrent.is_finished}>
              Finished
            </.pill>
            <.pill :if={!@modal_content.torrent.is_finished}>
              Downloading
            </.pill>
            <.pill>
              <%= @modal_content.torrent.percent_done %>%
            </.pill>
            <.pill>
              <%= Size.humanize!(@modal_content.torrent.size_when_done) %>
            </.pill>
          </div>
          <!-- Chart -->
          <div>
            <.line_graph
              id="line-chart-1"
              height={200}
              width="100%"
              type="bar"
              metric="volume"
              colors={["#03CEA4", "#FB4D3D"]}
              options={%{}}
              dataset={[
                %{
                  name: "Upload",
                  data:
                    Enum.map(
                      @modal_content.speeds,
                      fn [date, upload, _download] ->
                        [
                          DateTime.to_unix(date) * 1000,
                          if(upload != nil, do: Decimal.to_float(upload), else: 0.0)
                        ]
                      end
                    )
                },
                %{
                  name: "Download",
                  data:
                    Enum.map(
                      @modal_content.speeds,
                      fn [date, _upload, download] ->
                        [
                          DateTime.to_unix(date) * 1000,
                          Decimal.to_float(download || Decimal.new("0"))
                        ]
                      end
                    )
                }
              ]}
            />
          </div>
        </div>
      <% end %>
    </.modal>
    """
  end

  def torrent(assigns) do
    ~H"""
    <!-- Title and size -->
    <div class="flex flex-row">
      <div
        class="basis-3/4 text-left font-semibold"
        phx-click={
          JS.push("showing_modal", value: %{torrent_id: @torrent.id})
          |> show_modal("user-modal")
        }
      >
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
        <button
          phx-click="delete_torrent"
          phx-value-id={"delete-#{@torrent.id}"}
          data-confirm="Are you sure?"
        >
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
        <button
          :if={@torrent.status == :stopped}
          phx-click="start_torrent"
          phx-value-id={"play-#{@torrent.id}"}
        >
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
