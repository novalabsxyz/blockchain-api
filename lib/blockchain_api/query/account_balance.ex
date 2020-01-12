defmodule BlockchainAPI.Query.AccountBalance do
  @moduledoc false
  import Ecto.Query, warn: false
  use Timex

  alias BlockchainAPI.{Repo, Util, Schema.AccountBalance}

  def get_latest!(address) do
    AccountBalance
    |> where([a], a.account_address == ^address)
    |> order_by([a], desc: a.block_height)
    |> limit(1)
    |> Repo.replica.one!()
  end

  def create(attrs \\ %{}) do
    %AccountBalance{}
    |> AccountBalance.changeset(attrs)
    |> Repo.insert()
  end

  def get_history(address) do
    %{
      day: sample_daily_account_balance(address),
      week: sample_weekly_account_balance(address),
      month: sample_monthly_account_balance(address)
    }
  end

  # ==================================================================
  # Helper functions
  # ==================================================================
  defp get_account_balances_daily(address) do
    start = Util.shifted_unix_time(hours: -24)
    query_account_balance(address, start, Util.current_time())
  end

  defp get_account_balances_weekly(address) do
    start = Util.shifted_unix_time(days: -7)
    query_account_balance(address, start, Util.current_time())
  end

  defp get_account_balances_monthly(address) do
    start = Util.shifted_unix_time(days: -30)
    query_account_balance(address, start, Util.current_time())
  end

  defp query_account_balance(address, start, finish) do
    query =
      from(
        a in AccountBalance,
        where: a.account_address == ^address,
        where: a.block_time >= ^start,
        where: a.block_time <= ^finish,
        select: %{
          time: a.block_time,
          balance: a.balance,
          delta: a.delta
        }
      )

    query |> Repo.replica.all()
  end

  defp sample_daily_account_balance(address) do
    range = 1..24

    range
    |> balance_filter(address, &get_account_balances_daily/1, 1)
    |> populated_time_data()
    |> parse_balance_history(range, address)
  end

  defp sample_weekly_account_balance(address) do
    range = 1..22

    range
    |> balance_filter(address, &get_account_balances_weekly/1, 8)
    |> populated_time_data()
    |> parse_balance_history(range, address)
  end

  defp sample_monthly_account_balance(address) do
    range = 1..31

    range
    |> balance_filter(address, &get_account_balances_monthly/1, 24)
    |> populated_time_data()
    |> parse_balance_history(range, address)
  end

  defp balance_filter(range, address, fun, shift) do
    address
    |> interval_filter(range, fun, shift)
    |> Enum.reduce([], fn list, acc ->
      case list do
        list when list != [] ->
          x = list |> Enum.max_by(fn item -> item.time end)
          y = list |> Enum.map(fn item -> item.delta end) |> Enum.sum()
          [%{x | delta: y} | acc]

        _ ->
          [nil | acc]
      end
    end)
    |> Enum.reverse()
  end

  defp interval_filter(address, range, fun, shift) do
    hr_shift = 3600 * shift
    offset = rem(Util.current_time(), hr_shift)
    now = div(Util.current_time() - offset, hr_shift)
    then = div(Util.current_time() - (offset + hr_shift * length(Enum.to_list(range))), hr_shift)

    map =
      Range.new(then, now)
      |> Enum.map(fn key -> {key, []} end)
      |> Map.new()

    filtered_map =
      address
      |> fun.()
      |> Enum.group_by(fn x -> div(x.time - offset, hr_shift) end)

    map
    |> Map.merge(filtered_map)
    |> Map.values()
  end

  defp populated_time_data(filtered_time_data) do
    filtered_time_data
    |> Enum.reduce(
      {0, nil, []},
      fn
        nil, {p, nil, acc} ->
          {p + 1, nil, acc}

        nil, {_, current_balance, acc} ->
          {0, current_balance, acc ++ [current_balance]}

        %{balance: balance}, {0, _, acc0} ->
          {0, balance, acc0 ++ [balance]}

        %{balance: balance, delta: delta}, {p, _, acc0} ->
          acc1 =
            1..p
            |> Enum.to_list()
            |> Enum.reduce([], fn _, a -> [balance - delta | a] end)

          {0, balance, acc0 ++ acc1 ++ [balance]}
      end
    )
  end

  defp parse_balance_history(data, range, address) do
    case data do
      {0, _start, balances} -> balances
      _ -> default_balance_history(range, address)
    end
  end

  defp default_balance_history(range, address) do
    range
    |> Enum.map(fn _i ->
      case get_latest!(address) do
        nil -> 0
        account_entry -> account_entry.balance
      end
    end)
  end
end
