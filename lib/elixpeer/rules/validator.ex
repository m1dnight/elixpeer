defmodule Elixpeer.Rules.Validator do
  @moduledoc """
  Contains logic to validate the parsed rules for additional constraints.
  """
  alias Elixpeer.Rules.Parser
  alias Elixpeer.Rules.Rule
  alias Elixpeer.Rules.RuleSet

  @spec valid?(RuleSet.t() | Rule.t()) ::
          {:ok, RuleSet.t()} | {:ok, Rule.t()} | {:error, String.t()}
  def valid?(ruleset = %RuleSet{}) do
    with {:ok, _rule} <- valid?(ruleset.left),
         {:ok, _rule} <- valid?(ruleset.right) do
      {:ok, ruleset}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  @numerical_operators [{Kernel, :==}, {Kernel, :>=}, {Kernel, :<=}, {Kernel, :>}, {Kernel, :<}]
  @string_operators [{Regex, :match?}, {Kernel, :==}, {Parser, :not_match?}]
  def valid?(rule = %Rule{field: :age}) do
    if rule.operator in @numerical_operators do
      {:ok, rule}
    else
      {:error,
       "age operator must be one of #{inspect(@numerical_operators)}, given #{inspect(rule.operator)}"}
    end
  end

  def valid?(rule = %Rule{field: :ratio}) do
    if rule.operator in @numerical_operators do
      {:ok, rule}
    else
      {:error,
       "ratio operator must be one of #{inspect(@numerical_operators)}, given #{inspect(rule.operator)}"}
    end
  end

  def valid?(rule = %Rule{field: :tracker}) do
    if rule.operator in @string_operators do
      {:ok, rule}
    else
      {:error,
       "tracker operator must be one of #{inspect(@string_operators)}, given #{inspect(rule.operator)}"}
    end
  end
end
