defmodule TransmissionManager.Rule do
  @moduledoc """
  A rule for cleaning up torrents.

  """
  alias TransmissionManager.Torrent

  @type rule :: (Torrent.t() -> boolean()) | {:or, rule, rule} | {:and, rule, rule} | {:not, rule}
  @type action :: :delete | :ignore
  @type t :: %__MODULE__{
          :name => String.t(),
          :rule => rule,
          :action => action | nil,
          :enabled => boolean() | nil
        }

  @keys [:name, :rule, :action, :enabled]
  @enforce_keys [:name, :rule]
  defstruct @keys
end

defimpl String.Chars, for: TransmissionManager.Rule do
  def to_string(rule) do
    rule.name
  end
end
