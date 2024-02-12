defmodule TransmissionManager.Tracker do
  @moduledoc """
  Model of a transmission tracker.
  """
  alias __MODULE__

  @type t :: %__MODULE__{
          :id => integer(),
          :announce => String.t(),
          :scrape => String.t(),
          :tier => integer(),
          :sitename => String.t()
        }
  @keys [
    :id,
    :announce,
    :scrape,
    :tier,
    :sitename
  ]
  @enforce_keys @keys
  defstruct @keys
end
