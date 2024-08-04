defmodule ElixpeerWeb.Components.Charts do
  @moduledoc """
  Holds the charts components
  """
  use Phoenix.Component

  attr :id, :string, required: true
  attr :type, :string, default: "line"
  attr :width, :string, default: nil
  attr :height, :integer, default: nil
  attr :animated, :boolean, default: false
  attr :toolbar, :boolean, default: false
  attr :dataset, :list, default: []
  attr :categories, :list, default: []
  attr :options, :map, default: %{}
  attr :colors, :list, default: []
  attr :metric, :string, default: "rate"

  @spec line_graph(map()) :: Phoenix.LiveView.Rendered.t()
  def line_graph(assigns) do
    ~H"""
    <div
      id={@id}
      class="[&>div]:mx-auto"
      phx-hook="Chart"
      data-opts={Jason.encode!(trim(@options))}
      data-config={
        Jason.encode!(
          trim(%{
            height: @height,
            width: @width,
            type: @type
          })
        )
      }
      data-series={Jason.encode!(@dataset)}
      data-colors={Jason.encode!(@colors)}
      data-metric={@metric}
    >
    </div>
    """
  end

  defp trim(map) do
    Map.reject(map, fn {_key, val} -> is_nil(val) || val == "" end)
  end
end
