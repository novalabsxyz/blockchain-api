defmodule BlockchainAPI.Explorer.Account do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:address, :string, autogenerate: false}
  @derive {Phoenix.Param, key: :address}
  schema "accounts" do
    field :name, :string
    field :balance, :integer

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
