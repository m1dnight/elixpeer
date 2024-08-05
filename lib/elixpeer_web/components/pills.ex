# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule ElixpeerWeb.Components.Pills do
  @moduledoc """
  Components to render information
  """
  use Phoenix.Component

  attr :type, :string, default: "info"
  slot :inner_block, required: true

  def pill(assigns) do
    ~H"""
    <span class="bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-300 text-xs font-medium me-2 px-2.5 py-0.5 rounded">
      <%= render_slot(@inner_block) %>
    </span>
    """
  end
end
