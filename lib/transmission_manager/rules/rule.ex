defmodule TransmissionManager.Rules.Rule do
  @moduledoc """
  A rule to match torrents to.
  """

  @type t :: %__MODULE__{
          operator: := | :> | :< | :>= | :<= | :!=,
          field: atom(),
          value: any()
        }

  @keys [:operator, :field, :value]
  @enforce_keys [:operator, :field, :value]
  defstruct @keys
end

defmodule TransmissionManager.Rules.RuleSet do
  @moduledoc """
  A rule to match torrents to.
  """

  @type t :: %__MODULE__{
          combinator: :and | :or,
          left: t | TransmissionManager.Parser.Rule.t(),
          right: t | TransmissionManager.Parser.Rule.t()
        }

  @keys [:combinator, :left, :right]
  @enforce_keys [:combinator, :left, :right]
  defstruct @keys
end
