defmodule ParserTest do
  use ExUnit.Case

  alias TransmissionManager.Rules.Parser
  alias TransmissionManager.Rules.Rule
  alias TransmissionManager.Rules.RuleSet

  defp unwrap({:ok, [acc], "", _, _, _}), do: acc
  defp unwrap({:ok, _, rest, _, _, _}), do: {:error, "could not parse" <> rest}
  defp unwrap({:error, reason, _rest, _, _, _}), do: {:error, reason}

  describe "regex" do
    test "simple regex" do
      input = "/flacsfor.me/"
      output = ~r/flacsfor.me/
      assert Parser.regex(input) |> unwrap == output
    end

    test "regex with escape char" do
      input = "/flacsfor\\.me/"
      output = ~r/flacsfor\.me/
      assert Parser.regex(input) |> unwrap == output
    end

    test "regex with asterisk" do
      input = "/flacsfor.*/"
      output = ~r/flacsfor.*/
      assert Parser.regex(input) |> unwrap == output
    end
  end

  describe "string" do
    test "string" do
      input = "'astring'"
      output = "astring"
      assert Parser.string(input) |> unwrap == output
    end

    test "faulty string" do
      input = "123"
      output = {:error, "expected a valid string with single quotes"}

      assert Parser.string(input) |> unwrap == output
    end
  end

  describe "integer" do
    test "integer" do
      input = "123456"
      output = 123_456
      assert Parser.integer(input) |> unwrap == output
    end

    test "faulty integer" do
      input = "notaninteger"
      output = {:error, "expected ASCII character in the range \"0\" to \"9\""}
      assert Parser.integer(input) |> unwrap == output
    end
  end

  describe "float" do
    test "integer" do
      input = "12.34"
      output = 12.34
      assert Parser.float(input) |> unwrap == output
    end

    test "faulty integer" do
      input = "notaninteger"
      output = {:error, "expected ASCII character in the range \"0\" to \"9\""}
      assert Parser.integer(input) |> unwrap == output
    end
  end

  describe "operator" do
    test "all operators" do
      inputs = ["<", ">", "<=", ">=", "="]

      for input <- inputs do
        assert Kernel.match?({:ok, _, _, _, _, _}, Parser.operator(input))
      end
    end

    test "faulty operator" do
      input = "notanoperator"

      output =
        {:error,
         "expected string \"<=\" or string \">=\" or string \"~=\" or string \"!~=\" or string \"<\" or string \">\" or string \"=\""}

      assert Parser.operator(input) |> unwrap == output
    end
  end

  describe "combinator" do
    test "all combinators" do
      inputs = ["and", "or"]

      for input <- inputs do
        assert Kernel.match?({:ok, _, _, _, _, _}, Parser.combinator(input))
      end
    end

    test "faulty combinators" do
      input = "combinator"

      output = {:error, "expected string \"and\" or string \"or\""}

      assert Parser.combinator(input) |> unwrap == output
    end
  end

  describe "field" do
    test "valid fields" do
      inputs = ["age", "ratio", "tracker"]

      for input <- inputs do
        assert Kernel.match?({:ok, _, _, _, _, _}, Parser.field(input))
      end
    end

    test "faulty field" do
      input = "notafiel"
      output = {:error, "expected valid field name (age, ratio, or tracker)"}
      assert Parser.field(input) |> unwrap == output
    end
  end

  describe "value" do
    test "value float" do
      input = "12.34"
      output = 12.34
      assert Parser.value(input) |> unwrap == output
    end

    test "value integer" do
      input = "12"
      output = 12
      assert Parser.value(input) |> unwrap == output
    end

    test "value string" do
      input = "'astring'"
      output = "astring"
      assert Parser.value(input) |> unwrap == output
    end

    test "invalid value" do
      input = "***"

      output =
        {:error,
         "expected a valid string with single quotes while processing valid value (regex, integer, float, or string)"}

      assert Parser.value(input) |> unwrap == output
    end
  end

  describe "rule" do
    test "rule" do
      fields = [:age, :ratio, :tracker]

      operators = [
        {{Kernel, :<=}, "<="},
        {{Kernel, :>}, ">"},
        {{Kernel, :<=}, "<="},
        {{Kernel, :>=}, ">="},
        {{Kernel, :==}, "="}
      ]

      values = [{12, 12}, {12.34, 12.34}, {"astring", "'astring'"}]

      for field <- fields, {operator, operator_str} <- operators, {v, v_str} <- values do
        input = "#{field} #{operator_str} #{v_str}"

        output = %Rule{field: field, operator: operator, value: v}
        assert Parser.single_rule(input) |> unwrap == output, input
      end
    end
  end

  describe "rules" do
    test "generated rules" do
      fields = [:age, :ratio, :tracker]

      operators = [
        {{Kernel, :<=}, "<="},
        {{Kernel, :>}, ">"},
        {{Kernel, :<=}, "<="},
        {{Kernel, :>=}, ">="},
        {{Kernel, :==}, "="},
        {{Regex, :match?}, "~="}
      ]

      values = [{12, 12}, {12.34, 12.34}, {"astring", "'astring'"}]
      combinators = [{{Parser, :orr}, "or"}, {{Parser, :andd}, "and"}]

      for {combinator, combinator_str} <- combinators do
        for field1 <- fields, {operator1, operator_str1} <- operators, {v1, v1_str} <- values do
          for field2 <- fields, {operator2, operator_str2} <- operators, {v2, v2_str} <- values do
            # construct a combined rule
            rule1 = "#{field1} #{operator_str1} #{v1_str}"
            rule2 = "#{field2} #{operator_str2} #{v2_str}"
            input = "#{rule1} #{combinator_str} #{rule2}"

            # construct expected output
            output = %RuleSet{
              left: %Rule{value: v1, field: field1, operator: operator1},
              right: %Rule{value: v2, field: field2, operator: operator2},
              combinator: combinator
            }

            assert Parser.rules(input) |> unwrap == output
          end
        end
      end
    end

    test "regex rules" do
      input = "tracker ~= /flacsfor.me/"
      output = %Rule{field: :tracker, operator: {Regex, :match?}, value: ~r/flacsfor.me/}

      assert Parser.rules(input) |> unwrap == output
    end

    test "precedence and over or" do
      input = "age = 1 or age = 2 and age = 3"
      output1 = %Rule{value: 1, field: :age, operator: {Kernel, :==}}
      output2 = %Rule{value: 2, field: :age, operator: {Kernel, :==}}
      output3 = %Rule{value: 3, field: :age, operator: {Kernel, :==}}

      output = %RuleSet{
        left: output1,
        right: %RuleSet{left: output2, right: output3, combinator: {Parser, :andd}},
        combinator: {Parser, :orr}
      }

      assert Parser.rules(input) |> unwrap == output
    end

    test "precedence and and and" do
      input = "age = 1 and age = 2 and age = 3"
      output1 = %Rule{value: 1, field: :age, operator: {Kernel, :==}}
      output2 = %Rule{value: 2, field: :age, operator: {Kernel, :==}}
      output3 = %Rule{value: 3, field: :age, operator: {Kernel, :==}}

      output = %RuleSet{
        combinator: {Parser, :andd},
        left: %RuleSet{left: output1, right: output2, combinator: {Parser, :andd}},
        right: output3
      }

      assert Parser.rules(input) |> unwrap == output
    end

    test "grouping and or" do
      input = "age = 1 and (age = 2 or age = 3)"
      output1 = %Rule{value: 1, field: :age, operator: {Kernel, :==}}
      output2 = %Rule{value: 2, field: :age, operator: {Kernel, :==}}
      output3 = %Rule{value: 3, field: :age, operator: {Kernel, :==}}

      output = %RuleSet{
        combinator: {Parser, :andd},
        left: output1,
        right: %RuleSet{left: output2, right: output3, combinator: {Parser, :orr}}
      }

      assert Parser.rules(input) |> unwrap == output
    end

    test "grouping or and" do
      input = "age = 1 or (age = 2 and age = 3)"
      output1 = %Rule{value: 1, field: :age, operator: {Kernel, :==}}
      output2 = %Rule{value: 2, field: :age, operator: {Kernel, :==}}
      output3 = %Rule{value: 3, field: :age, operator: {Kernel, :==}}

      output = %RuleSet{
        combinator: {Parser, :orr},
        left: output1,
        right: %RuleSet{left: output2, right: output3, combinator: {Parser, :andd}}
      }

      assert Parser.rules(input) |> unwrap == output
    end
  end

  describe "errors" do
    test "invalid field" do
      input = "notafiel = 1"
      output = {:error, "expected valid rule or multiple rules in parentheses"}
      assert Parser.rules(input) |> unwrap == output
    end

    test "invalid combinator" do
      input = "age = 10 xor age = 10"
      output = {:error, "expected end of string"}
      assert Parser.rules(input) |> unwrap == output
    end
  end
end
