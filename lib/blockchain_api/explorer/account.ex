defmodule BlockchainAPI.Explorer.Account do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Phoenix.Param, key: :address}
  @derive {Jason.Encoder, only: [:id, :address, :name, :balance]}
  schema "accounts" do
    field :name, :string
    field :balance, :integer, null: false
    field :address, :string, null: false

    timestamps()

  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:address, :name, :balance])
    |> validate_required([:address, :balance])
    |> unique_constraint(:address)
  end
end
