defmodule BlockchainAPI.PaymentsNotifier do
  @bones 100000000
  @ticker "HLM"

  alias BlockchainAPI.{NotifierClient, Util}

  def send_notification(txn) do
    amount = :blockchain_txn_payment_v1.amount(txn)
    msg = amount |> units() |> message()
    NotifierClient.post(payment_data(txn, amount), msg)
  end

  defp payment_data(txn, amount) do
    %{
      address: Util.bin_to_string(:blockchain_txn_payment_v1.payee(txn)),
      amount: amount,
      hash: Util.bin_to_string(:blockchain_txn_payment_v1.hash(txn)),
      type: "receivedPayment"
    }
  end

  defp message(units) do
    "You got #{units} #{@ticker}"
  end

  def units(amount) when is_integer(amount) do
    amount |> Decimal.div(@bones) |> delimit_unit()
  end
  def units(amount) when is_float(amount) do
    amount |> Decimal.from_float() |> Decimal.div(@bones) |> delimit_unit()
  end

  defp delimit_unit(units0) do
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
