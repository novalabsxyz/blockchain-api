defmodule BlockchainAPI.Test.Data.Block do
  import BlockchainAPI.Test.Factory
  use BlockchainAPI.DataCase
  alias BlockchainAPI.Query

  test "single block insert" do
    _block = insert(:block)
    blocks = Query.Block.list(%{})
    assert length(blocks) == 1
  end

  test "multiple block insert" do
    _blocks = Enum.map(1..200, fn(_) -> insert(:block) end)
    queried = Query.Block.list(%{"limit" => "200"})
    assert length(queried) == 200
  end
end
