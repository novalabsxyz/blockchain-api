defmodule BlockchainAPI.BlockchainAPITest do
  use BlockchainAPI.DataCase

  alias BlockchainAPI.DBManager
  @default_params %{page: 1, page_size: 10}

  describe "blocks" do
    alias Schema.Block

    @valid_attrs %{hash: "some hash", height: 42, round: 42, time: 42}
    @invalid_attrs %{hash: nil, height: nil, round: nil, time: nil}

    def block_fixture(attrs \\ %{}) do
      {:ok, block} =
        attrs
        |> Enum.into(@valid_attrs)
        |> DBManager.create_block()

      block
    end

    test "list_blocks/0 returns all blocks" do
      block = block_fixture()
      assert DBManager.list_blocks(@default_params).entries == [block]
    end

    test "get_block!/1 returns the block with given id" do
      block = block_fixture()
      assert DBManager.get_block!(block.height) == block
    end

    test "create_block/1 with valid data creates a block" do
      assert {:ok, %Block{} = block} = DBManager.create_block(@valid_attrs)
      assert block.hash == "some hash"
      assert block.height == 42
      assert block.round == 42
      assert block.time == 42
    end

    test "create_block/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = DBManager.create_block(@invalid_attrs)
    end

  end
end
