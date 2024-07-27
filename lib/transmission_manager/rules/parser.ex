defmodule TransmissionManager.Rules.Parser do
  @moduledoc """

  Syntax:

  fields: age, ratio
  operators: <, >, <=, >=, =
  values: integer | float | string

  combinators: and, or

  rule: field operator value | rule operator rule
  """
  import NimbleParsec

  alias __MODULE__
  alias TransmissionManager.Rules.Rule
  alias TransmissionManager.Rules.RuleSet
  alias TransmissionManager.Rules.Validator

  #############################################################################
  # Operators

  def not_match?(x, y), do: not Regex.match?(x, y)

  def orr(x, y), do: x or y

  def andd(x, y), do: x and y

  #############################################################################
  # Helpers

  whitespace = ascii_char([?\s, ?\t, ?\n, ?\r])

  spaces = ignore(times(whitespace, min: 1))

  defp atomize(acc) do
    acc |> hd() |> String.to_atom()
  end

  defp parse_string([acc]) do
    acc
  end

  defp to_regex(acc) do
    acc
    |> to_string()
    |> Regex.compile!()
  end

  #############################################################################
  # Literals

  # -- Regex

  regex =
    ignore(ascii_char([?/]))
    |> times(ascii_char([{:not, ?/}]), min: 1)
    |> ignore(ascii_char([?/]))
    |> label("valid regular expression")
    |> reduce(:to_regex)

  defparsec :regex, regex

  # -- Strings
  string =
    ignore(ascii_char([?']))
    |> ascii_string([{:not, ?'}], min: 1)
    |> ignore(ascii_char([?']))
    |> reduce(:parse_string)
    |> label("a valid string with single quotes")

  defparsec :string, string

  # -- Integers

  int = integer(min: 1)

  defparsec :integer, int

  # -- Float

  float =
    ascii_string([?0..?9], min: 1)
    |> ignore(ascii_char([?.]))
    |> concat(ascii_string([?0..?9], min: 1))
    |> reduce(:parse_float)

  defp parse_float(acc) do
    acc
    |> Enum.join(".")
    |> String.to_float()
  end

  defparsec :float, float

  # -- Operator

  operator =
    choice([
      string("<=") |> replace({Kernel, :<=}),
      string(">=") |> replace({Kernel, :>=}),
      string("~=") |> replace({Regex, :match?}),
      string("!~=") |> replace({Parser, :not_match?}),
      string("<") |> replace({Kernel, :<}),
      string(">") |> replace({Kernel, :>}),
      string("=") |> replace({Kernel, :==})
    ])

  defparsec :operator, operator

  # -- Combinator
  comb_and =
    string("and")
    |> replace({Parser, :andd})

  comb_or =
    string("or")
    |> replace({Parser, :orr})

  combinator =
    choice([
      comb_and,
      comb_or
    ])

  defparsec :combinator, combinator

  #############################################################################
  # Value

  defparsec :value,
            choice([regex, float, int, string])
            |> label("valid value (regex, integer, float, or string)")

  #############################################################################
  # Field

  defparsec :field,
            choice([string("age"), string("ratio"), string("tracker"), string("days-inactive")])
            |> reduce(:atomize)
            |> label("valid field name (age, ratio, tracker or days-inactive)")

  #############################################################################
  # Rule

  defp parse_rule([field, operator, value]) do
    %Rule{field: field, operator: operator, value: value}
  end

  rule =
    parsec(:field)
    |> ignore(whitespace)
    |> parsec(:operator)
    |> ignore(whitespace)
    |> parsec(:value)
    |> reduce(:parse_rule)
    |> label("valid rule")

  defparsec :single_rule, rule

  #############################################################################
  # Group

  # defp fold_infixl(acc) do
  #   acc
  #   |> Enum.reverse()
  #   |> Enum.chunk_every(2)
  #   |> List.foldr([], fn
  #     [l], [] -> l
  #     [r, op], l -> {op, [l, r]}
  #   end)
  # end

  defp fold(acc) do
    acc
    |> Enum.reverse()
    |> Enum.chunk_every(2)
    |> List.foldr([], fn
      [l], [] ->
        l

      [r, op], l ->
        %RuleSet{combinator: op, left: l, right: r}
    end)
  end

  lparen = ascii_char([?\(])
  rparen = ascii_char([?\)])

  # (<rule>)
  group =
    ignore(lparen)
    |> parsec(:or_rule)
    |> ignore(rparen)

  # <rule> | <group>
  defparsec :rule_unit,
            choice([parsec(:single_rule), group])
            |> label("valid rule or multiple rules in parentheses")

  # <rule> and <rule>
  defparsec :and_rule,
            parsec(:rule_unit)
            |> repeat(spaces |> concat(comb_and) |> concat(spaces) |> parsec(:rule_unit))
            |> reduce(:fold)

  # <rule> or <rule>
  defparsec :or_rule,
            parsec(:and_rule)
            |> repeat(spaces |> concat(comb_or) |> concat(spaces) |> parsec(:and_rule))
            |> reduce(:fold)

  defparsec :rules, parsec(:or_rule) |> eos()

  #############################################################################
  # Entrypoint

  defp unwrap({:ok, [acc], "", _, _, _}), do: {:ok, acc}
  defp unwrap({:ok, _, rest, _, _, _}), do: {:error, "could not parse ruleset" <> rest}
  defp unwrap({:error, reason, _rest, _, _, _}), do: {:error, reason}

  @spec parse(String.t()) :: {:ok, RuleSet.t()} | {:error, String.t()}
  def parse(input) do
    with result <- rules(input),
         {:ok, result} <- unwrap(result),
         {:ok, rule} <- Validator.valid?(result) do
      {:ok, rule}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end
end
