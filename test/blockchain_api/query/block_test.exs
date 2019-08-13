defmodule BlockchainAPI.BlockTest do
  use BlockchainAPI.DataCase

  alias BlockchainAPI.Query

  describe "blocks" do
    alias BlockchainAPI.Schema.Block

    @valid_attrs %{hash: "some hash", height: 42, round: 42, time: 42}
    @invalid_attrs %{hash: nil, height: nil, round: nil, time: nil}

    def block_fixture(attrs \\ %{}) do
      {:ok, block} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Query.Block.create()

      block
    end

    test "list_blocks/0 returns all blocks" do
      block = block_fixture()
      [b] = Query.Block.list(%{"limit" => "1"})
      assert b.height == block.height and b.time == block.time
    end

    test "get_block!/1 returns the block with given id" do
      block = block_fixture()
      b = Query.Block.get!(block.height)
      assert b.height == block.height and b.time == block.time
    end

    test "create_block/1 with valid data creates a block" do
      assert {:ok, %Block{} = block} = Query.Block.create(@valid_attrs)
      assert block.hash == "some hash"
      assert block.height == 42
      assert block.round == 42
      assert block.time == 42
    end

    test "create_block/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Query.Block.create(@invalid_attrs)
    end

  end
end
