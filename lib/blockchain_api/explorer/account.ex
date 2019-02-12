defmodule BlockchainAPI.Explorer.Account do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Phoenix.Param, key: :address}
  @derive {Jason.Encoder, only: [:id, :address, :name, :balance, :fee, :nonce]}
  schema "accounts" do
    field :name, :string
    field :balance, :integer, null: false
    field :address, :string, null: false
    field :fee, :integer, null: false
    field :nonce, :integer, null: false

    timestamps()

  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:address, :name, :balance, :fee, :nonce])
    |> validate_required([:address, :balance, :fee, :nonce])
    |> unique_constraint(:address)
  end
end
