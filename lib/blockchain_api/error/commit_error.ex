defmodule BlockchainAPI.CommitError do
  @moduledoc false
  defexception [:message]

  @impl true
  def exception(value) do
    msg = "Unexpected! Got: #{inspect(value)}"
    %BlockchainAPI.CommitError{message: msg}
  end
end
