defmodule BlockchainAPI.Schema.AccountTransaction do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util, Schema.AccountTransaction}
  @fields [:id, :account_address, :txn_hash, :txn_type, :txn_status]

  @derive {Jason.Encoder, only: @fields}
  schema "account_transactions" do
    field :account_address, :binary, null: false
    field :txn_hash, :binary, null: false
    field :txn_type, :string, null: false
    field :txn_status, :string, null: false

    timestamps()
  end

  @doc false
  def changeset(account_transaction, attrs) do
    account_transaction
    |> cast(attrs, [:account_address, :txn_hash, :txn_type, :txn_status])
    |> validate_required([:account_address, :txn_hash, :txn_type, :txn_status])
    |> unique_constraint(:unique_account_txn, name: :unique_account_txn)
  end

  def encode_model(account_transaction) do
    %{Map.take(account_transaction, @fields) |
      txn_hash: Util.bin_to_string(account_transaction.txn_hash),
      account_address: Util.bin_to_string(account_transaction.account_address)
    }
  end

  defimpl Jason.Encoder, for: AccountTransaction do
    def encode(account_transaction, opts) do
      account_transaction
      |> AccountTransaction.encode_model()
      |> Jason.Encode.map(opts)
    end
  end

  def map_cleared(:blockchain_txn_coinbase_v1, txn) do
    %{
      account_address: :blockchain_txn_coinbase_v1.payee(txn),
      txn_type: "coinbase",
      txn_status: "cleared",
      txn_hash: :blockchain_txn_coinbase_v1.hash(txn)
    }
  end
  def map_cleared(:blockchain_txn_security_coinbase_v1, txn) do
    %{
      account_address: :blockchain_txn_security_coinbase_v1.payee(txn),
      txn_type: "security",
      txn_status: "cleared",
      txn_hash: :blockchain_txn_security_coinbase_v1.hash(txn)
    }
  end
  def map_cleared(:blockchain_txn_add_gateway_v1, txn) do
    %{
      account_address: :blockchain_txn_add_gateway_v1.owner(txn),
      txn_type: "gateway",
      txn_status: "cleared",
      txn_hash: :blockchain_txn_add_gateway_v1.hash(txn)
    }
  end
  def map_cleared(:blockchain_txn_assert_location_v1, txn) do
    %{
      account_address: :blockchain_txn_assert_location_v1.owner(txn),
      txn_type: "location",
      txn_status: "cleared",
      txn_hash: :blockchain_txn_assert_location_v1.hash(txn)
    }
  end
  def map_cleared(:blockchain_txn_gen_gateway_v1, txn) do
    %{
      account_address: :blockchain_txn_gen_gateway_v1.owner(txn),
      txn_type: "gateway",
      txn_status: "cleared",
      txn_hash: :blockchain_txn_gen_gateway_v1.hash(txn)
    }
  end

  def map_cleared(:blockchain_txn_payment_v1, :payee, txn) do
    %{
      account_address: :blockchain_txn_payment_v1.payee(txn),
      txn_type: "payment",
      txn_status: "cleared",
      txn_hash: :blockchain_txn_payment_v1.hash(txn)
    }
  end
  def map_cleared(:blockchain_txn_payment_v1, :payer, txn) do
    %{
      account_address: :blockchain_txn_payment_v1.payer(txn),
      txn_type: "payment",
      txn_status: "cleared",
      txn_hash: :blockchain_txn_payment_v1.hash(txn)
    }
  end
  def map_cleared(:blockchain_txn_reward_v1, hash, txn) do
    %{
      account_address: :blockchain_txn_reward_v1.account(txn),
      txn_type: "#{Atom.to_string(:blockchain_txn_reward_v1.type(txn))}_reward",
      txn_status: "cleared",
      txn_hash: hash
    }
  end

  def map_pending(:blockchain_txn_coinbase_v1, txn) do
    %{
      account_address: :blockchain_txn_coinbase_v1.payee(txn),
      txn_type: "coinbase",
      txn_status: "pending",
      txn_hash: :blockchain_txn_coinbase_v1.hash(txn)
    }
  end
  def map_pending(:blockchain_txn_add_gateway_v1, txn) do
    %{
      account_address: :blockchain_txn_add_gateway_v1.owner(txn),
      txn_type: "gateway",
      txn_status: "pending",
      txn_hash: :blockchain_txn_add_gateway_v1.hash(txn)
    }
  end
  def map_pending(:blockchain_txn_assert_location_v1, txn) do
    %{
      account_address: :blockchain_txn_assert_location_v1.owner(txn),
      txn_type: "location",
      txn_status: "pending",
      txn_hash: :blockchain_txn_assert_location_v1.hash(txn)
    }
  end
  def map_pending(:blockchain_txn_payment_v1, txn) do
    %{
      account_address: :blockchain_txn_payment_v1.payer(txn),
      txn_type: "payment",
      txn_status: "pending",
      txn_hash: :blockchain_txn_payment_v1.hash(txn)
    }
  end
end
