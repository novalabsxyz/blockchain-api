defmodule NotifierTest do
  use ExUnit.Case
  @bones 100000000

  test "whole number far greater than bones" do
    amount = 1000000000000000
    converted = units(amount)
    assert converted == "10,000,000"
  end

  test "whole number greater than bones" do
    amount = 1000000000
    converted = units(amount)
    assert converted == "10"
  end

  test "decimal number greater than bones" do
    amount = 1000000000.10
    converted = units(amount)
    assert converted == "10.000000001"
  end

  test "whole number less than bones" do
    amount = 10000
    converted = units(amount)
    assert converted == "0.0001"
  end

  test "decimal number less than bones" do
    amount = 10000.123
    converted = units(amount)
    assert converted == "0.00010000123"
  end

  defp units(amount) when is_integer(amount) do
    units0 = Decimal.div(amount, @bones)
    unit_str = units0 |> Decimal.to_string()

    case :binary.match(unit_str, ".") do
      {start, _} ->
        precision = byte_size(unit_str) - start - 1
        units0
        |> Decimal.to_float()
        |> Number.Delimit.number_to_delimited(precision: precision)
        |> String.trim_trailing("0")

      :nomatch ->
        units0
        |> Decimal.to_float()
        |> Number.Delimit.number_to_delimited(precision: 0)
    end
  end
  defp units(amount) when is_float(amount) do
    units0 = amount |> Decimal.from_float() |> Decimal.div(@bones)
    unit_str = units0 |> Decimal.to_string()

    case :binary.match(unit_str, ".") do
      {start, _} ->
        precision = byte_size(unit_str) - start - 1
        units0
        |> Decimal.to_float()
        |> Number.Delimit.number_to_delimited(precision: precision)
        |> String.trim_trailing("0")

      :nomatch ->
        units0
        |> Decimal.to_float()
        |> Number.Delimit.number_to_delimited(precision: 0)
    end
  end
end
