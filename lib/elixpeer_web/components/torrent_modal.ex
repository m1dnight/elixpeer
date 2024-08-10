# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule ElixpeerWeb.Components.TorrentModal do
  @moduledoc """
  Defines a modal to show details about a torrent.
  """
  use Phoenix.Component

  import ElixpeerWeb.CoreComponents
  import ElixpeerWeb.Components.Pills
  import ElixpeerWeb.Components.Charts

  def torrent_modal(assigns) do
    ~H"""
    <.modal id="user-modal">
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
                      @modal_content.activity,
                      fn bucket ->
                        [DateTime.to_unix(bucket.bucket) * 1000, Decimal.to_float(bucket.uploaded)]
                      end
                    )
                },
                %{
                  name: "Download",
                  data:
                    Enum.map(
                      @modal_content.activity,
                      fn bucket ->
                        [DateTime.to_unix(bucket.bucket) * 1000, Decimal.to_float(bucket.downloaded)]
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
end
