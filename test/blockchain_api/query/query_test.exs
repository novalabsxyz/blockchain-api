defmodule BlockchainAPI.QueryTest do
  use BlockchainAPI.DataCase

  alias BlockchainAPI.{Util, Query}
  alias BlockchainAPI.Schema.Transaction

  @block_valid_attrs %{hash: "some hash", height: 42, round: 42, time: 42}
  @transaction_valid_attrs %{hash: "some hash", type: "some type"}
  @transaction_invalid_attrs %{hash: nil, type: nil}
  @query_params %{}

  describe "transactions" do

    def transaction_fixture(attrs \\ %{}) do
      {:ok, block} = Query.Block.create(@block_valid_attrs)
      assert {:ok, %Transaction{} = transaction} = Query.Transaction.create(block.height, attrs)
      transaction
    end

    test "get_transaction!/1 returns the transaction with given hash" do
      transaction = transaction_fixture(@transaction_valid_attrs)
      assert Query.Transaction.get!(transaction.hash) == transaction
    end

    test "create_transaction/1 with valid data creates a transaction" do
      transaction = transaction_fixture(@transaction_valid_attrs)
      assert transaction.type == "some type"
      assert transaction.hash == "some hash"
    end

    test "create_transaction/1 with invalid data returns error changeset" do
      {:ok, block} = Query.Block.create(@block_valid_attrs)
      assert {:error, %Ecto.Changeset{} = transaction} = Query.Transaction.create(block.height, @transaction_invalid_attrs)
    end
  end

  describe "coinbase_transactions" do
    alias BlockchainAPI.Schema.CoinbaseTransaction

    @valid_attrs %{hash: "some hash", amount: 42, payee: "some payee"}
    @invalid_attrs %{hash: nil, amount: nil, payee: nil}

    def coinbase_fixture(attrs \\ %{}) do
      {:ok, block} = Query.Block.create(@block_valid_attrs)
      assert {:ok, %Transaction{} = transaction} = Query.Transaction.create(block.height, @transaction_valid_attrs)
      assert {:ok, %CoinbaseTransaction{} = coinbase} = Query.CoinbaseTransaction.create(attrs)
      coinbase
    end

    test "list_coinbase_transactions/0 returns all coinbase_transactions" do
      coinbase = coinbase_fixture(@valid_attrs)
      [c] = Query.CoinbaseTransaction.list(@query_params)
      assert c == coinbase
    end

    test "get_coinbase!/1 returns the coinbase with given hash" do
      coinbase = coinbase_fixture(@valid_attrs)
      assert Query.CoinbaseTransaction.get!(coinbase.hash) == coinbase
    end

    test "create_coinbase/1 with valid data creates a coinbase" do
      coinbase = coinbase_fixture(@valid_attrs)
      assert coinbase.amount == 42
      assert coinbase.payee == "some payee"
    end

    test "create_coinbase/1 with invalid data returns error changeset" do
      {:ok, block} = Query.Block.create(@block_valid_attrs)
      assert {:ok, %Transaction{} = transaction} = Query.Transaction.create(block.height, @transaction_valid_attrs)
      assert {:error, %Ecto.Changeset{}} = Query.CoinbaseTransaction.create(@invalid_attrs)
    end

  end

  describe "payment_transactions" do
    alias BlockchainAPI.Schema.PaymentTransaction

    @valid_attrs %{hash: "some hash", amount: 42, fee: 42, nonce: 42, payee: "some payee", payer: "some payer"}
    @invalid_attrs %{hash: nil, amount: nil, fee: nil, nonce: nil, payee: nil, payer: nil}

    def payment_fixture(attrs \\ %{}) do
      {:ok, block} = Query.Block.create(@block_valid_attrs)
      assert {:ok, %Transaction{} = transaction} = Query.Transaction.create(block.height, @transaction_valid_attrs)
      assert {:ok, %PaymentTransaction{} = payment} = Query.PaymentTransaction.create(attrs)
      payment
    end

    test "list_payment_transactions/0 returns all payment_transactions" do
      payment = payment_fixture(@valid_attrs)
      [p] = Query.PaymentTransaction.list(@query_params)
      assert p == payment
    end

    test "get_payment!/1 returns the payment with given hash" do
      payment = payment_fixture(@valid_attrs)
      assert Query.PaymentTransaction.get!(payment.hash) == payment
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
      {:ok, block} = Query.Block.create(@block_valid_attrs)
      assert {:ok, %Transaction{} = transaction} = Query.Transaction.create(block.height, @transaction_valid_attrs)
      assert {:error, %Ecto.Changeset{}} = Query.PaymentTransaction.create(@invalid_attrs)
    end
  end

  describe "gateway_transactions" do
    alias BlockchainAPI.Schema.GatewayTransaction

    @valid_attrs %{hash: "some hash", gateway: "some gateway", owner: "some owner"}
    @invalid_attrs %{hash: nil, gateway: nil, owner: nil}

    def gateway_fixture(attrs \\ %{}) do
      {:ok, block} = Query.Block.create(@block_valid_attrs)
      assert {:ok, %Transaction{} = transaction} = Query.Transaction.create(block.height, @transaction_valid_attrs)
      assert {:ok, %GatewayTransaction{} = gateway} = Query.GatewayTransaction.create(attrs)
      gateway
    end

    test "list_gateway_transactions/0 returns all add_gateway_transactions" do
      gateway = gateway_fixture(@valid_attrs)
      [g] = Query.GatewayTransaction.list(@query_params)
      assert (g.owner == Util.bin_to_string(gateway.owner) and
        g.gateway == Util.bin_to_string(gateway.gateway) and
        g.gateway_hash == Util.bin_to_string(gateway.hash))
    end

    test "get_gateway!/1 returns the gateway with given hash" do
      gateway = gateway_fixture(@valid_attrs)
      assert Query.GatewayTransaction.get!(gateway.hash) == gateway
    end

    test "create_gateway/1 with valid data creates a gateway" do
      gateway = gateway_fixture(@valid_attrs)
      assert gateway.gateway == "some gateway"
      assert gateway.owner == "some owner"
    end

    test "create_gateway/1 with invalid data returns error changeset" do
      {:ok, block} = Query.Block.create(@block_valid_attrs)
      assert {:ok, %Transaction{} = transaction} = Query.Transaction.create(block.height, @transaction_valid_attrs)
      assert {:error, %Ecto.Changeset{}} = Query.GatewayTransaction.create(@invalid_attrs)
    end
  end

  describe "location_transactions" do
    alias BlockchainAPI.Schema.{GatewayTransaction, LocationTransaction}

    @valid_attrs %{hash: "some hash", fee: 42, gateway: "some gateway", location: "some location", nonce: 42, owner: "some owner", payer: "some payer"}
    @invalid_attrs %{hash: nil, fee: nil, gateway: nil, location: nil, nonce: nil, owner: nil}

    def gateway_location_fixture(attrs \\ %{}) do
      {:ok, block} = Query.Block.create(@block_valid_attrs)
      assert {:ok, %Transaction{} = transaction} = Query.Transaction.create(block.height, @transaction_valid_attrs)
      assert {:ok, %GatewayTransaction{} = gateway} = Query.GatewayTransaction.create(attrs)
      assert {:ok, %LocationTransaction{} = gateway_location} = Query.LocationTransaction.create(attrs)
      gateway_location
    end

    test "list_location_transactions/0 returns all assert_location_transactions" do
      gateway_location = gateway_location_fixture(@valid_attrs)
      [l] = Query.LocationTransaction.list(@query_params)
      assert l == gateway_location
    end

    test "get_location!/1 returns the gateway_location with given hash" do
      gateway_location = gateway_location_fixture(@valid_attrs)
      assert Query.LocationTransaction.get!(gateway_location.hash) == gateway_location
    end

    test "create_location/1 with valid data creates a gateway_location" do
      gateway_location = gateway_location_fixture(@valid_attrs)
      assert gateway_location.fee == 42
      assert gateway_location.hash == "some hash"
      assert gateway_location.gateway == "some gateway"
      assert gateway_location.location == "some location"
      assert gateway_location.nonce == 42
      assert gateway_location.owner == "some owner"
    end

    test "create_location/1 with invalid data returns error changeset" do
      {:ok, block} = Query.Block.create(@block_valid_attrs)
      assert {:ok, %Transaction{} = transaction} = Query.Transaction.create(block.height, @transaction_valid_attrs)
      assert {:error, %Ecto.Changeset{}} = Query.LocationTransaction.create(@invalid_attrs)
    end

  end

  describe "accounts" do
    @valid_attrs %{address: "some address", balance: 42, fee: 42, nonce: 42}

    def account_fixture(attrs \\ %{}) do
      {:ok, account} = Query.Account.create(attrs)
      account
    end

    test "create account with valid attrs" do
      account = account_fixture(@valid_attrs)
      assert account.address == "some address"
      assert account.balance == 42
      assert account.fee == 42
      assert account.nonce == 42
    end

    test "get_account!/1 returns account with given address" do
      account = account_fixture(@valid_attrs)
      assert Query.Account.get!(account.address) == account
    end

  end


end
