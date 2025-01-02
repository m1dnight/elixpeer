# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule ElixpeerWeb.Components.TorrentModal do
  @moduledoc """
  Defines a modal to show details about a torrent.
  """
  use Phoenix.Component

  import ElixpeerWeb.CoreComponents
  import ElixpeerWeb.Components.Pills

  def torrent_modal(assigns) do
    ~H"""
    <.modal id={@id}>
      <%= if @torrent == nil do %>
        <p>Nothing to see here</p>
      <% else %>
        <div>
          <!-- Title -->
          <div class="flex flex-row mb-4 break-all">
            <div class="basis-full text-center text-xl">
              <%= @torrent.name %>
            </div>
          </div>
          <!-- pills -->
          <div class="flex flex-row justify-center">
            <.pill :if={@torrent.is_finished}>
              Finished
            </.pill>
            <.pill :if={!@torrent.is_finished}>
              Downloading
            </.pill>
            <.pill>
              <%= @torrent.percent_done %>%
            </.pill>
            <.pill>
              <%= Size.humanize!(@torrent.size_when_done) %>
            </.pill>
            <.pill :for={t <- @torrent.trackers} type="warn">
              <%= t.sitename %>
            </.pill>
          </div>
        </div>
        <!-- Chart -->
        <div>
          <div phx-update="ignore" id={"torrent-chart-#{@torrent.id}"} phx-hook="Chart"></div>
        </div>
      <% end %>
    </.modal>
    """
  end
end

# <!-- pills -->
#   <div class="flex flex-row justify-center">
#     <.pill :if={@torrent.is_finished}>
#       Finished
#     </.pill>
#     <.pill :if={!@torrent.is_finished}>
#       Downloading
#     </.pill>
#     <.pill>
#       <%= @torrent.percent_done %>%
#     </.pill>
#     <.pill>
#       <%= Size.humanize!(@torrent.size_when_done) %>
#     </.pill>
#   </div>
#   <!-- Chart -->
#   <div>
#     <.line_graph
#       id={"torrent-chart-#{@torrent.id}"}
#       height={200}
#       width="100%"
#       type="bar"
#       metric="volume"
#       colors={["#03CEA4", "#FB4D3D"]}
#       options={%{}}
#       dataset={[]}
#     />
#   </div>
# </div>
