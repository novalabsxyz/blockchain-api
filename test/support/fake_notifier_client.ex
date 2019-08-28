defmodule BlockchainAPI.FakeNotifierClient do
  def post(_data, _message, _send_address, _opts \\ %{}) do
    {:ok, %{}}
  end
end
