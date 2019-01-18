defmodule BlockchainAPI.BlockchainAPITest do
  use BlockchainAPI.DataCase

  alias BlockchainAPI.BlockchainAPI

  describe "blocks" do
    alias BlockchainAPI.BlockchainAPI.Block

    @valid_attrs %{hash: "some hash", height: 42, round: 42, time: 42}
    @update_attrs %{hash: "some updated hash", height: 43, round: 43, time: 43}
    @invalid_attrs %{hash: nil, height: nil, round: nil, time: nil}

    def block_fixture(attrs \\ %{}) do
      {:ok, block} =
        attrs
        |> Enum.into(@valid_attrs)
        |> BlockchainAPI.create_block()

      block
    end

    test "list_blocks/0 returns all blocks" do
      block = block_fixture()
      assert BlockchainAPI.list_blocks() == [block]
    end

    test "get_block!/1 returns the block with given id" do
      block = block_fixture()
      assert BlockchainAPI.get_block!(block.id) == block
    end

    test "create_block/1 with valid data creates a block" do
      assert {:ok, %Block{} = block} = BlockchainAPI.create_block(@valid_attrs)
      assert block.hash == "some hash"
      assert block.height == 42
      assert block.round == 42
      assert block.time == 42
    end

    test "create_block/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = BlockchainAPI.create_block(@invalid_attrs)
    end

    test "update_block/2 with valid data updates the block" do
      block = block_fixture()
      assert {:ok, %Block{} = block} = BlockchainAPI.update_block(block, @update_attrs)
      assert block.hash == "some updated hash"
      assert block.height == 43
      assert block.round == 43
      assert block.time == 43
    end

    test "update_block/2 with invalid data returns error changeset" do
      block = block_fixture()
      assert {:error, %Ecto.Changeset{}} = BlockchainAPI.update_block(block, @invalid_attrs)
      assert block == BlockchainAPI.get_block!(block.id)
    end

    test "delete_block/1 deletes the block" do
      block = block_fixture()
      assert {:ok, %Block{}} = BlockchainAPI.delete_block(block)
      assert_raise Ecto.NoResultsError, fn -> BlockchainAPI.get_block!(block.id) end
    end

    test "change_block/1 returns a block changeset" do
      block = block_fixture()
      assert %Ecto.Changeset{} = BlockchainAPI.change_block(block)
    end
  end
end
