defmodule BlockchainAPI.ExplorerTest do
  use BlockchainAPI.DataCase

  alias BlockchainAPI.Explorer
  alias BlockchainAPI.Explorer.Transaction
  alias BlockchainAPI.Explorer.Block

  @block_valid_attrs %{hash: "some hash", height: 42, round: 42, time: 42}
  @block_invalid_attrs %{hash: nil, height: nil, round: nil, time: nil}
  @transaction_valid_attrs %{hash: "some hash", type: "some type"}
  @transaction_invalid_attrs %{hash: nil, type: nil}
  @default_params %{page: 1, page_size: 10}

  describe "blocks" do

    def block_fixture(attrs \\ %{}) do
      {:ok, block} =
        attrs
        |> Enum.into(@block_valid_attrs)
        |> Explorer.create_block()

      block
    end

    test "list_blocks/0 returns all blocks" do
      block = block_fixture()
      assert Explorer.list_blocks(@default_params).entries == [block]
    end

    test "get_block!/1 returns the block with given id" do
      block = block_fixture()
      assert Explorer.get_block!(block.height) == block
    end

    test "create_block/1 with valid data creates a block" do
      assert {:ok, %Block{} = block} = Explorer.create_block(@block_valid_attrs)
      assert block.hash == "some hash"
      assert block.height == 42
      assert block.round == 42
      assert block.time == 42
    end

    test "create_block/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Explorer.create_block(@block_invalid_attrs)
    end

  end

  describe "transactions" do

    def transaction_fixture(attrs \\ %{}) do
      {:ok, block} = Explorer.create_block(@block_valid_attrs)
      assert {:ok, %Transaction{} = transaction} = Explorer.create_transaction(block.height, attrs)
      transaction
    end

    test "get_transaction!/1 returns the transaction with given hash" do
      transaction = transaction_fixture(@transaction_valid_attrs)
      assert Explorer.get_transaction!(transaction.hash) == transaction
    end

    test "create_transaction/1 with valid data creates a transaction" do
      transaction = transaction_fixture(@transaction_valid_attrs)
      assert transaction.type == "some type"
      assert transaction.hash == "some hash"
    end

    test "create_transaction/1 with invalid data returns error changeset" do
      {:ok, block} = Explorer.create_block(@block_valid_attrs)
      assert {:error, %Ecto.Changeset{} = transaction} = Explorer.create_transaction(block.height, @transaction_invalid_attrs)
    end
  end

  describe "coinbase_transactions" do
    alias BlockchainAPI.Explorer.CoinbaseTransaction

    @valid_attrs %{coinbase_hash: "some hash", amount: 42, payee: "some payee"}
    @invalid_attrs %{coinbase_hash: nil, amount: nil, payee: nil}

    def coinbase_fixture(attrs \\ %{}) do
      {:ok, block} = Explorer.create_block(@block_valid_attrs)
      assert {:ok, %Transaction{} = transaction} = Explorer.create_transaction(block.height, @transaction_valid_attrs)
      assert {:ok, %CoinbaseTransaction{} = coinbase} = Explorer.create_coinbase(transaction.hash, attrs)
      coinbase
    end

    test "list_coinbase_transactions/0 returns all coinbase_transactions" do
      coinbase = coinbase_fixture(@valid_attrs)
      assert Explorer.list_coinbase_transactions(@default_params).entries == [coinbase]
    end

    test "get_coinbase!/1 returns the coinbase with given hash" do
      coinbase = coinbase_fixture(@valid_attrs)
      assert Explorer.get_coinbase!(coinbase.coinbase_hash) == coinbase
    end

    test "create_coinbase/1 with valid data creates a coinbase" do
      coinbase = coinbase_fixture(@valid_attrs)
      assert coinbase.amount == 42
      assert coinbase.payee == "some payee"
    end

    test "create_coinbase/1 with invalid data returns error changeset" do
      {:ok, block} = Explorer.create_block(@block_valid_attrs)
      assert {:ok, %Transaction{} = transaction} = Explorer.create_transaction(block.height, @transaction_valid_attrs)
      assert {:error, %Ecto.Changeset{}} = Explorer.create_coinbase(transaction.hash, @invalid_attrs)
    end

  end

  describe "payment_transactions" do
    alias BlockchainAPI.Explorer.PaymentTransaction

    @valid_attrs %{payment_hash: "some hash", amount: 42, fee: 42, nonce: 42, payee: "some payee", payer: "some payer"}
    @invalid_attrs %{payment_hash: nil, amount: nil, fee: nil, nonce: nil, payee: nil, payer: nil}

    def payment_fixture(attrs \\ %{}) do
      {:ok, block} = Explorer.create_block(@block_valid_attrs)
      assert {:ok, %Transaction{} = transaction} = Explorer.create_transaction(block.height, @transaction_valid_attrs)
      assert {:ok, %PaymentTransaction{} = payment} = Explorer.create_payment(transaction.hash, attrs)
      payment
    end

    test "list_payment_transactions/0 returns all payment_transactions" do
      payment = payment_fixture(@valid_attrs)
      assert Explorer.list_payment_transactions(@default_params).entries == [payment]
    end

    test "get_payment!/1 returns the payment with given hash" do
      payment = payment_fixture(@valid_attrs)
      assert Explorer.get_payment!(payment.payment_hash) == payment
    end

    test "create_payment/1 with valid data creates a payment" do
      payment = payment_fixture(@valid_attrs)
      assert payment.amount == 42
      assert payment.fee == 42
      assert payment.nonce == 42
      assert payment.payee == "some payee"
      assert payment.payer == "some payer"
    end

    test "create_payment/1 with invalid data returns error changeset" do
      {:ok, block} = Explorer.create_block(@block_valid_attrs)
      assert {:ok, %Transaction{} = transaction} = Explorer.create_transaction(block.height, @transaction_valid_attrs)
      assert {:error, %Ecto.Changeset{}} = Explorer.create_payment(transaction.hash, @invalid_attrs)
    end
  end

  describe "gateway_transactions" do
    alias BlockchainAPI.Explorer.GatewayTransaction

    @valid_attrs %{gateway_hash: "some hash", gateway: "some gateway", owner: "some owner"}
    @invalid_attrs %{gateway_hash: nil, gateway: nil, owner: nil}

    def gateway_fixture(attrs \\ %{}) do
      {:ok, block} = Explorer.create_block(@block_valid_attrs)
      assert {:ok, %Transaction{} = transaction} = Explorer.create_transaction(block.height, @transaction_valid_attrs)
      assert {:ok, %GatewayTransaction{} = gateway} = Explorer.create_gateway(transaction.hash, attrs)
      gateway
    end

    test "list_gateway_transactions/0 returns all add_gateway_transactions" do
      gateway = gateway_fixture(@valid_attrs)
      assert Explorer.list_gateway_transactions(@default_params).entries == [gateway]
    end

    test "get_gateway!/1 returns the gateway with given gateway_hash" do
      gateway = gateway_fixture(@valid_attrs)
      assert Explorer.get_gateway!(gateway.gateway_hash) == gateway
    end

    test "create_gateway/1 with valid data creates a gateway" do
      gateway = gateway_fixture(@valid_attrs)
      assert gateway.gateway == "some gateway"
      assert gateway.owner == "some owner"
    end

    test "create_gateway/1 with invalid data returns error changeset" do
      {:ok, block} = Explorer.create_block(@block_valid_attrs)
      assert {:ok, %Transaction{} = transaction} = Explorer.create_transaction(block.height, @transaction_valid_attrs)
      assert {:error, %Ecto.Changeset{}} = Explorer.create_gateway(transaction.hash, @invalid_attrs)
    end
  end

  describe "location_transactions" do
    alias BlockchainAPI.Explorer.LocationTransaction

    @valid_attrs %{location_hash: "some hash", fee: 42, gateway: "some gateway", location: "some location", nonce: 42, owner: "some owner"}
    @invalid_attrs %{location_hash: nil, fee: nil, gateway: nil, location: nil, nonce: nil, owner: nil}

    def gateway_location_fixture(attrs \\ %{}) do
      {:ok, block} = Explorer.create_block(@block_valid_attrs)
      assert {:ok, %Transaction{} = transaction} = Explorer.create_transaction(block.height, @transaction_valid_attrs)
      assert {:ok, %LocationTransaction{} = gateway_location} = Explorer.create_location(transaction.hash, attrs)
      gateway_location
    end

    test "list_location_transactions/0 returns all assert_location_transactions" do
      gateway_location = gateway_location_fixture(@valid_attrs)
      assert Explorer.list_location_transactions(@default_params).entries == [gateway_location]
    end

    test "get_location!/1 returns the gateway_location with given location_hash" do
      gateway_location = gateway_location_fixture(@valid_attrs)
      assert Explorer.get_location!(gateway_location.location_hash) == gateway_location
    end

    test "create_location/1 with valid data creates a gateway_location" do
      gateway_location = gateway_location_fixture(@valid_attrs)
      assert gateway_location.fee == 42
      assert gateway_location.location_hash == "some hash"
      assert gateway_location.gateway == "some gateway"
      assert gateway_location.location == "some location"
      assert gateway_location.nonce == 42
      assert gateway_location.owner == "some owner"
    end

    test "create_location/1 with invalid data returns error changeset" do
      {:ok, block} = Explorer.create_block(@block_valid_attrs)
      assert {:ok, %Transaction{} = transaction} = Explorer.create_transaction(block.height, @transaction_valid_attrs)
      assert {:error, %Ecto.Changeset{}} = Explorer.create_location(transaction.hash, @invalid_attrs)
    end

  end

  describe "accounts" do
    alias BlockchainAPI.Explorer.Account

    @valid_attrs %{address: "some address", balance: 42}
    @invalid_attrs %{address: nil, balance: nil}

    def account_fixture(attrs \\ %{}) do
      {:ok, account} = Explorer.create_account(attrs)
      account
    end

    test "create account with valid attrs" do
      account = account_fixture(@valid_attrs)
      assert account.address == "some address"
      assert account.balance == 42
    end

    test "get_account!/1 returns account with given address" do
      account = account_fixture(@valid_attrs)
      assert Explorer.get_account!(account.address) == account
    end

  end


end
