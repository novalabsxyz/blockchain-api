defmodule BlockchainAPI.RewardsNotifier do
  alias BlockchainAPI.{Query.RewardTxn, NotifierClient}

  @schedule 100 * 60 * 60 * 24 * 7

  def schedule_notifications() do
    :timer.apply_interval(@schedule, __MODULE__, :send_notifications, [])
  end

  def send_notifications do
    Timex.now()
    |> Timex.shift(days: -7)
    |> Timex.to_unix()
    |> RewardTxn.get_after()
    |> Enum.map(fn reward ->
      NotifierClient.post(reward_data(reward), message(reward))
    end)
  end

  defp reward_data(reward) do
    %{
      address: reward.account,
      amount: reward.amount,
      type: "receivedRewards"
    }
  end

  defp message(reward) do
    "You received #{reward.amount} rewards this week!"
  end
end
