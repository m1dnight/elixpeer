defmodule ParserTest do
  use ExUnit.Case

  alias TransmissionManager.Rules.Parser

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
      input = "astring"
      output = "astring"
      assert Parser.string(input) |> unwrap == output
    end

    test "faulty string" do
      input = "123"
      output = {:error, "expected ASCII character in the range \"a\" to \"z\""}

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
         "expected string \"<=\" or string \">=\" or string \"~=\" or string \"<\" or string \">\" or string \"=\""}

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
      input = "astring"
      output = "astring"
      assert Parser.value(input) |> unwrap == output
    end

    test "invalid value" do
      input = "***"
      output = {:error, "expected valid value (integer, float, or string)"}
      assert Parser.value(input) |> unwrap == output
    end
  end

  describe "rule" do
    test "rule" do
      fields = ["age", "ratio", "tracker"]
      operators = ["<", ">", "<=", ">=", "="]
      values = ["12", "12.34", "astring"]

      for field <- fields, operator <- operators, value <- values do
        input = "#{field} #{operator} #{value}"

        # construct expected output
        output_field = String.to_atom(field)
        output_operator = String.to_atom(operator)

        output_value =
          case {Integer.parse(value), Float.parse(value)} do
            {{int, ""}, _} -> int
            {_, {float, ""}} -> float
            _ -> value
          end

        output = %{field: output_field, operator: output_operator, value: output_value}
        assert Parser.single_rule(input) |> unwrap == output, input
      end
    end
  end

  describe "rules" do
    test "generated rules" do
      fields = [:age, :ratio, :tracker]
      operators = [:<, :>, :<=, :>=, :=]
      values = [12, 12.34, "astring"]
      combinators = [:or, :and]

      for combinator <- combinators do
        for field1 <- fields, operator1 <- operators, value1 <- values do
          for field2 <- fields, operator2 <- operators, value2 <- values do
            # construct a combined rule
            rule1 = "#{field1} #{operator1} #{value1}"
            rule2 = "#{field2} #{operator2} #{value2}"
            input = "#{rule1} #{combinator} #{rule2}"

            # construct expected output
            output = %{
              left: %{value: value1, field: field1, operator: operator1},
              right: %{value: value2, field: field2, operator: operator2},
              combinator: combinator
            }

            assert Parser.rules(input) |> unwrap == output, input
          end
        end
      end
    end

    test "precedence and over or" do
      input = "age = 1 or age = 2 and age = 3"
      output_1 = %{value: 1, field: :age, operator: :=}
      output2 = %{value: 2, field: :age, operator: :=}
      output3 = %{value: 3, field: :age, operator: :=}

      output = %{
        left: output_1,
        right: %{left: output2, right: output3, combinator: :and},
        combinator: :or
      }

      assert Parser.rules(input) |> unwrap == output
    end

    test "precedence and and and" do
      input = "age = 1 and age = 2 and age = 3"
      output1 = %{value: 1, field: :age, operator: :=}
      output2 = %{value: 2, field: :age, operator: :=}
      output3 = %{value: 3, field: :age, operator: :=}

      output = %{
        combinator: :and,
        left: %{left: output1, right: output2, combinator: :and},
        right: output3
      }

      assert Parser.rules(input) |> unwrap == output
    end

    test "grouping and or" do
      input = "age = 1 and (age = 2 or age = 3)"
      output1 = %{value: 1, field: :age, operator: :=}
      output2 = %{value: 2, field: :age, operator: :=}
      output3 = %{value: 3, field: :age, operator: :=}

      output = %{
        combinator: :and,
        left: output1,
        right: %{left: output2, right: output3, combinator: :or}
      }

      assert Parser.rules(input) |> unwrap == output
    end

    test "grouping or and" do
      input = "age = 1 or (age = 2 and age = 3)"
      output1 = %{value: 1, field: :age, operator: :=}
      output2 = %{value: 2, field: :age, operator: :=}
      output3 = %{value: 3, field: :age, operator: :=}

      output = %{
        combinator: :or,
        left: output1,
        right: %{left: output2, right: output3, combinator: :and}
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
