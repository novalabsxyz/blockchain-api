defmodule BlockchainAPI.ExplorerTest do
  use BlockchainAPI.DataCase

  alias BlockchainAPI.Explorer

  describe "blocks" do
    alias BlockchainAPI.Explorer.Block

    @valid_attrs %{hash: "some hash", height: 42, round: 42, time: 42}
    @update_attrs %{hash: "some updated hash", height: 43, round: 43, time: 43}
    @invalid_attrs %{hash: nil, height: nil, round: nil, time: nil}

    def block_fixture(attrs \\ %{}) do
      {:ok, block} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Explorer.create_block()

      block
    end

    test "list_blocks/0 returns all blocks" do
      block = block_fixture()
      assert Explorer.list_blocks() == [block]
    end

    test "get_block!/1 returns the block with given id" do
      block = block_fixture()
      assert Explorer.get_block!(block.id) == block
    end

    test "create_block/1 with valid data creates a block" do
      assert {:ok, %Block{} = block} = Explorer.create_block(@valid_attrs)
      assert block.hash == "some hash"
      assert block.height == 42
      assert block.round == 42
      assert block.time == 42
    end

    test "create_block/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Explorer.create_block(@invalid_attrs)
    end

    test "update_block/2 with valid data updates the block" do
      block = block_fixture()
      assert {:ok, %Block{} = block} = Explorer.update_block(block, @update_attrs)
      assert block.hash == "some updated hash"
      assert block.height == 43
      assert block.round == 43
      assert block.time == 43
    end

    test "update_block/2 with invalid data returns error changeset" do
      block = block_fixture()
      assert {:error, %Ecto.Changeset{}} = Explorer.update_block(block, @invalid_attrs)
      assert block == Explorer.get_block!(block.id)
    end

    test "delete_block/1 deletes the block" do
      block = block_fixture()
      assert {:ok, %Block{}} = Explorer.delete_block(block)
      assert_raise Ecto.NoResultsError, fn -> Explorer.get_block!(block.id) end
    end

    test "change_block/1 returns a block changeset" do
      block = block_fixture()
      assert %Ecto.Changeset{} = Explorer.change_block(block)
    end
  end

  describe "transactions" do
    alias BlockchainAPI.Explorer.Transaction

    @valid_attrs %{type: "some type"}
    @update_attrs %{type: "some updated type"}
    @invalid_attrs %{type: nil}

    def transaction_fixture(attrs \\ %{}) do
      {:ok, transaction} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Explorer.create_transaction()

      transaction
    end

    test "list_transactions/0 returns all transactions" do
      transaction = transaction_fixture()
      assert Explorer.list_transactions() == [transaction]
    end

    test "get_transaction!/1 returns the transaction with given id" do
      transaction = transaction_fixture()
      assert Explorer.get_transaction!(transaction.id) == transaction
    end

    test "create_transaction/1 with valid data creates a transaction" do
      assert {:ok, %Transaction{} = transaction} = Explorer.create_transaction(@valid_attrs)
      assert transaction.type == "some type"
    end

    test "create_transaction/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Explorer.create_transaction(@invalid_attrs)
    end

    test "update_transaction/2 with valid data updates the transaction" do
      transaction = transaction_fixture()
      assert {:ok, %Transaction{} = transaction} = Explorer.update_transaction(transaction, @update_attrs)
      assert transaction.type == "some updated type"
    end

    test "update_transaction/2 with invalid data returns error changeset" do
      transaction = transaction_fixture()
      assert {:error, %Ecto.Changeset{}} = Explorer.update_transaction(transaction, @invalid_attrs)
      assert transaction == Explorer.get_transaction!(transaction.id)
    end

    test "delete_transaction/1 deletes the transaction" do
      transaction = transaction_fixture()
      assert {:ok, %Transaction{}} = Explorer.delete_transaction(transaction)
      assert_raise Ecto.NoResultsError, fn -> Explorer.get_transaction!(transaction.id) end
    end

    test "change_transaction/1 returns a transaction changeset" do
      transaction = transaction_fixture()
      assert %Ecto.Changeset{} = Explorer.change_transaction(transaction)
    end
  end

  describe "coinbase_transactions" do
    alias BlockchainAPI.Explorer.Coinbase

    @valid_attrs %{amount: 42, payee: "some payee", type: "some type"}
    @update_attrs %{amount: 43, payee: "some updated payee", type: "some updated type"}
    @invalid_attrs %{amount: nil, payee: nil, type: nil}

    def coinbase_fixture(attrs \\ %{}) do
      {:ok, coinbase} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Explorer.create_coinbase()

      coinbase
    end

    test "list_coinbase_transactions/0 returns all coinbase_transactions" do
      coinbase = coinbase_fixture()
      assert Explorer.list_coinbase_transactions() == [coinbase]
    end

    test "get_coinbase!/1 returns the coinbase with given id" do
      coinbase = coinbase_fixture()
      assert Explorer.get_coinbase!(coinbase.id) == coinbase
    end

    test "create_coinbase/1 with valid data creates a coinbase" do
      assert {:ok, %Coinbase{} = coinbase} = Explorer.create_coinbase(@valid_attrs)
      assert coinbase.amount == 42
      assert coinbase.payee == "some payee"
      assert coinbase.type == "some type"
    end

    test "create_coinbase/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Explorer.create_coinbase(@invalid_attrs)
    end

    test "update_coinbase/2 with valid data updates the coinbase" do
      coinbase = coinbase_fixture()
      assert {:ok, %Coinbase{} = coinbase} = Explorer.update_coinbase(coinbase, @update_attrs)
      assert coinbase.amount == 43
      assert coinbase.payee == "some updated payee"
      assert coinbase.type == "some updated type"
    end

    test "update_coinbase/2 with invalid data returns error changeset" do
      coinbase = coinbase_fixture()
      assert {:error, %Ecto.Changeset{}} = Explorer.update_coinbase(coinbase, @invalid_attrs)
      assert coinbase == Explorer.get_coinbase!(coinbase.id)
    end

    test "delete_coinbase/1 deletes the coinbase" do
      coinbase = coinbase_fixture()
      assert {:ok, %Coinbase{}} = Explorer.delete_coinbase(coinbase)
      assert_raise Ecto.NoResultsError, fn -> Explorer.get_coinbase!(coinbase.id) end
    end

    test "change_coinbase/1 returns a coinbase changeset" do
      coinbase = coinbase_fixture()
      assert %Ecto.Changeset{} = Explorer.change_coinbase(coinbase)
    end
  end

  describe "payment_transactions" do
    alias BlockchainAPI.Explorer.Payment

    @valid_attrs %{amount: 42, fee: 42, nonce: 42, payee: "some payee", payer: "some payer", type: "some type"}
    @update_attrs %{amount: 43, fee: 43, nonce: 43, payee: "some updated payee", payer: "some updated payer", type: "some updated type"}
    @invalid_attrs %{amount: nil, fee: nil, nonce: nil, payee: nil, payer: nil, type: nil}

    def payment_fixture(attrs \\ %{}) do
      {:ok, payment} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Explorer.create_payment()

      payment
    end

    test "list_payment_transactions/0 returns all payment_transactions" do
      payment = payment_fixture()
      assert Explorer.list_payment_transactions() == [payment]
    end

    test "get_payment!/1 returns the payment with given id" do
      payment = payment_fixture()
      assert Explorer.get_payment!(payment.id) == payment
    end

    test "create_payment/1 with valid data creates a payment" do
      assert {:ok, %Payment{} = payment} = Explorer.create_payment(@valid_attrs)
      assert payment.amount == 42
      assert payment.fee == 42
      assert payment.nonce == 42
      assert payment.payee == "some payee"
      assert payment.payer == "some payer"
      assert payment.type == "some type"
    end

    test "create_payment/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Explorer.create_payment(@invalid_attrs)
    end

    test "update_payment/2 with valid data updates the payment" do
      payment = payment_fixture()
      assert {:ok, %Payment{} = payment} = Explorer.update_payment(payment, @update_attrs)
      assert payment.amount == 43
      assert payment.fee == 43
      assert payment.nonce == 43
      assert payment.payee == "some updated payee"
      assert payment.payer == "some updated payer"
      assert payment.type == "some updated type"
    end

    test "update_payment/2 with invalid data returns error changeset" do
      payment = payment_fixture()
      assert {:error, %Ecto.Changeset{}} = Explorer.update_payment(payment, @invalid_attrs)
      assert payment == Explorer.get_payment!(payment.id)
    end

    test "delete_payment/1 deletes the payment" do
      payment = payment_fixture()
      assert {:ok, %Payment{}} = Explorer.delete_payment(payment)
      assert_raise Ecto.NoResultsError, fn -> Explorer.get_payment!(payment.id) end
    end

    test "change_payment/1 returns a payment changeset" do
      payment = payment_fixture()
      assert %Ecto.Changeset{} = Explorer.change_payment(payment)
    end
  end

  describe "add_gateway_transactions" do
    alias BlockchainAPI.Explorer.Gateway

    @valid_attrs %{gateway: "some gateway", owner: "some owner", type: "some type"}
    @update_attrs %{gateway: "some updated gateway", owner: "some updated owner", type: "some updated type"}
    @invalid_attrs %{gateway: nil, owner: nil, type: nil}

    def gateway_fixture(attrs \\ %{}) do
      {:ok, gateway} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Explorer.create_gateway()

      gateway
    end

    test "list_add_gateway_transactions/0 returns all add_gateway_transactions" do
      gateway = gateway_fixture()
      assert Explorer.list_add_gateway_transactions() == [gateway]
    end

    test "get_gateway!/1 returns the gateway with given id" do
      gateway = gateway_fixture()
      assert Explorer.get_gateway!(gateway.id) == gateway
    end

    test "create_gateway/1 with valid data creates a gateway" do
      assert {:ok, %Gateway{} = gateway} = Explorer.create_gateway(@valid_attrs)
      assert gateway.gateway == "some gateway"
      assert gateway.owner == "some owner"
      assert gateway.type == "some type"
    end

    test "create_gateway/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Explorer.create_gateway(@invalid_attrs)
    end

    test "update_gateway/2 with valid data updates the gateway" do
      gateway = gateway_fixture()
      assert {:ok, %Gateway{} = gateway} = Explorer.update_gateway(gateway, @update_attrs)
      assert gateway.gateway == "some updated gateway"
      assert gateway.owner == "some updated owner"
      assert gateway.type == "some updated type"
    end

    test "update_gateway/2 with invalid data returns error changeset" do
      gateway = gateway_fixture()
      assert {:error, %Ecto.Changeset{}} = Explorer.update_gateway(gateway, @invalid_attrs)
      assert gateway == Explorer.get_gateway!(gateway.id)
    end

    test "delete_gateway/1 deletes the gateway" do
      gateway = gateway_fixture()
      assert {:ok, %Gateway{}} = Explorer.delete_gateway(gateway)
      assert_raise Ecto.NoResultsError, fn -> Explorer.get_gateway!(gateway.id) end
    end

    test "change_gateway/1 returns a gateway changeset" do
      gateway = gateway_fixture()
      assert %Ecto.Changeset{} = Explorer.change_gateway(gateway)
    end
  end

  describe "assert_location_transactions" do
    alias BlockchainAPI.Explorer.GatewayLocation

    @valid_attrs %{fee: 42, gateway: "some gateway", location: "some location", nonce: 42, owner: "some owner", type: "some type"}
    @update_attrs %{fee: 43, gateway: "some updated gateway", location: "some updated location", nonce: 43, owner: "some updated owner", type: "some updated type"}
    @invalid_attrs %{fee: nil, gateway: nil, location: nil, nonce: nil, owner: nil, type: nil}

    def gateway_location_fixture(attrs \\ %{}) do
      {:ok, gateway_location} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Explorer.create_gateway_location()

      gateway_location
    end

    test "list_assert_location_transactions/0 returns all assert_location_transactions" do
      gateway_location = gateway_location_fixture()
      assert Explorer.list_assert_location_transactions() == [gateway_location]
    end

    test "get_gateway_location!/1 returns the gateway_location with given id" do
      gateway_location = gateway_location_fixture()
      assert Explorer.get_gateway_location!(gateway_location.id) == gateway_location
    end

    test "create_gateway_location/1 with valid data creates a gateway_location" do
      assert {:ok, %GatewayLocation{} = gateway_location} = Explorer.create_gateway_location(@valid_attrs)
      assert gateway_location.fee == 42
      assert gateway_location.gateway == "some gateway"
      assert gateway_location.location == "some location"
      assert gateway_location.nonce == 42
      assert gateway_location.owner == "some owner"
      assert gateway_location.type == "some type"
    end

    test "create_gateway_location/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Explorer.create_gateway_location(@invalid_attrs)
    end

    test "update_gateway_location/2 with valid data updates the gateway_location" do
      gateway_location = gateway_location_fixture()
      assert {:ok, %GatewayLocation{} = gateway_location} = Explorer.update_gateway_location(gateway_location, @update_attrs)
      assert gateway_location.fee == 43
      assert gateway_location.gateway == "some updated gateway"
      assert gateway_location.location == "some updated location"
      assert gateway_location.nonce == 43
      assert gateway_location.owner == "some updated owner"
      assert gateway_location.type == "some updated type"
    end

    test "update_gateway_location/2 with invalid data returns error changeset" do
      gateway_location = gateway_location_fixture()
      assert {:error, %Ecto.Changeset{}} = Explorer.update_gateway_location(gateway_location, @invalid_attrs)
      assert gateway_location == Explorer.get_gateway_location!(gateway_location.id)
    end

    test "delete_gateway_location/1 deletes the gateway_location" do
      gateway_location = gateway_location_fixture()
      assert {:ok, %GatewayLocation{}} = Explorer.delete_gateway_location(gateway_location)
      assert_raise Ecto.NoResultsError, fn -> Explorer.get_gateway_location!(gateway_location.id) end
    end

    test "change_gateway_location/1 returns a gateway_location changeset" do
      gateway_location = gateway_location_fixture()
      assert %Ecto.Changeset{} = Explorer.change_gateway_location(gateway_location)
    end
  end
end
