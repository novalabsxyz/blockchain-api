defmodule BlockchainAPI.Explorer.Account do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:address, :string, autogenerate: false}
  @derive {Phoenix.Param, key: :address}
  schema "blocks" do
    field :name, :string
    field :balance, :integer
    field :public_key, :string

    timestamps()
  end

  @doc false
  def changeset(block, attrs) do
    block
    |> cast(attrs, [:address, :name, :balance, :public_key])
    |> validate_required([:address, :balance, :public_key])
    |> unique_constraint(:address)
    |> unique_constraint(:public_key)
  end
end
