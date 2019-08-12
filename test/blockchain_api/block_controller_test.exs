defmodule BlockchainAPIWeb.BlockControllerTest do
  use BlockchainAPIWeb.ConnCase
  alias BlockchainAPI.Query

  @num_blocks 2000
  @default_limit 100
  @max_limit 1000

  setup do
    blocks = Range.new(1, @num_blocks)
             |> Enum.map(
               fn(h) ->
                 block_map = %{hash: :crypto.strong_rand_bytes(32), height: h, round: h, time: h}
                 {:ok, b} = Query.Block.create(block_map)
                 b
               end)
    case length(blocks) == @num_blocks do
      true -> :ok
      false -> :error
    end
  end

  test "block index/2 returns #{@default_limit} blocks with no limit", %{conn: conn} do
    %{"data" => blocks} = conn
                          |> get(Routes.block_path(conn, :index, %{}))
                          |> json_response(200)

    assert length(blocks) == @default_limit
  end

  test "block index/2 returns #{@max_limit} blocks when limit > #{@max_limit}", %{conn: conn} do
    %{"data" => blocks} = conn
                          |> get(Routes.block_path(conn, :index, %{"limit" => 5000}))
                          |> json_response(200)

    assert length(blocks) == @max_limit
  end

  test "block index/2 before without limit", %{conn: conn} do
    %{"data" => blocks} = conn
                          |> get(Routes.block_path(conn, :index, %{"before" => 200}))
                          |> json_response(200)

    assert length(blocks) == @default_limit
  end

  test "block index/2 with valid limit", %{conn: conn} do
    %{"data" => blocks} = conn
                          |> get(Routes.block_path(conn, :index, %{"limit" => 400}))
                          |> json_response(200)

    assert length(blocks) == 400
  end

  test "block index/2 before with invalid limit", %{conn: conn} do
    %{"data" => blocks} = conn
                          |> get(Routes.block_path(conn, :index, %{"before" => 1800, "limit" => 1500}))
                          |> json_response(200)

    assert length(blocks) == @max_limit
  end
end

