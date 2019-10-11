defmodule BlockchainAPI.PaymentsNotifier do
  @ticker "HNT"

  alias BlockchainAPI.Util

  def send_notification(txn) do
    amount = :blockchain_txn_payment_v1.amount(txn)
    msg = amount |> Util.units() |> message()
    data = payment_data(txn, amount)
    Util.notifier_client().post(data, msg, data.address)
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
end
