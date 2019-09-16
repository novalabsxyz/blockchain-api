defmodule BlockchainAPI.Schema.Account do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util, Schema.Account}
  @fields [:id, :address, :name, :balance, :fee, :nonce]

  @derive {Phoenix.Param, key: :address}
  @derive {Jason.Encoder, only: @fields}
  schema "accounts" do
    field :name, :string, null: true
    field :balance, :integer, null: false
    field :address, :binary, null: false
    field :fee, :integer, null: false, default: 0
    field :nonce, :integer, null: false, default: 0

    timestamps()
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:address, :name, :balance, :fee, :nonce])
    |> validate_required([:address, :balance, :fee, :nonce])
    |> unique_constraint(:address, name: :unique_account_address)
  end

  def encode_model(account) do
    %{
      Map.take(account, @fields)
      | address: Util.bin_to_string(account.address)
    }
  end

  defimpl Jason.Encoder, for: Account do
    def encode(account, opts) do
      account
      |> Account.encode_model()
      |> Jason.Encode.map(opts)
    end
  end
end
