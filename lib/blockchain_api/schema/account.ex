defmodule BlockchainAPI.Schema.Account do
  use Ecto.Schema
  import Ecto.Changeset
  alias BlockchainAPI.{Util, Schema.Account}

  @fields [
    :id,
    :address,
    :name,
    :balance,
    :dc_balance,
    :security_balance,
    :fee,
    :nonce,
    :dc_nonce,
    :security_nonce
  ]

  @derive {Phoenix.Param, key: :address}
  @derive {Jason.Encoder, only: @fields}
  schema "accounts" do
    field :name, :string, null: true
    field :address, :binary, null: false
    field :balance, :integer, null: false, default: 0
    field :dc_balance, :integer, null: false, default: 0
    field :security_balance, :integer, null: false, default: 0
    field :fee, :integer, null: false, default: 0
    field :nonce, :integer, null: false, default: 0
    field :dc_nonce, :integer, null: false, default: 0
    field :security_nonce, :integer, null: false, default: 0

    timestamps()
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [
      :address,
      :name,
      :balance,
      :dc_balance,
      :security_balance,
      :fee,
      :nonce,
      :dc_nonce,
      :security_nonce
    ])
    |> validate_required([:address, :balance, :fee, :nonce])
    |> unique_constraint(:address)
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
