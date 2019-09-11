defmodule PaymentsNotifierTest do
  use ExUnit.Case

  alias BlockchainAPI.Util

  test "whole number far greater than bones" do
    amount = 1000000000000000
    converted = Util.units(amount)
    assert converted == "10,000,000"
  end

  test "whole number greater than bones" do
    amount = 1000000000
    converted = Util.units(amount)
    assert converted == "10"
  end

  test "decimal number greater than bones" do
    amount = 1000000000.10
    converted = Util.units(amount)
    assert converted == "10.000000001"
  end

  test "whole number less than bones" do
    amount = 10000
    converted = Util.units(amount)
    assert converted == "0.0001"
  end

  test "decimal number less than bones" do
    amount = 10000.123
    converted = Util.units(amount)
    assert converted == "0.00010000123"
  end
end
