defmodule TransmissionManager.Rule do
  @moduledoc """
  A rule for cleaning up torrents.

  """
  alias TransmissionManager.Torrent

  @type rule :: (Torrent.t() -> boolean()) | rule
  @type action :: :delete | :ignore
  @type t :: %__MODULE__{
          :name => String.t(),
          :rule => rule,
          :action => action,
          :enabled => boolean()
        }

  @keys [:name, :rule, :action, :enabled]
  @enforce_keys @keys
  defstruct @keys

  @spec new(String.t(), rule, action, boolean()) :: t()
  def new(name, rule, action, enabled \\ true) do
    %__MODULE__{
      name: name,
      rule: rule,
      action: action,
      enabled: enabled
    }
  end

  @spec match?(t(), Torrent.t()) :: boolean()
  def match?(rule, torrent) do
    rule.rule.(torrent)
  end
end

defimpl String.Chars, for: TransmissionManager.Rule do
  def to_string(rule) do
    rule.name
  end
end
