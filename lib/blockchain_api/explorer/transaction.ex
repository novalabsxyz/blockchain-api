defmodule BlockchainAPI.Explorer.Transaction do
  use Ecto.Schema
  import Ecto.Changeset


  @derive {Phoenix.Param, key: :hash}
  @derive {Jason.Encoder, only: [:id, :hash, :type, :block_height]}
  schema "transactions" do
    field :type, :string, null: false
    field :block_height, :integer, null: false
    field :hash, :string, null: false

    timestamps()
  end

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:hash, :type, :block_height])
    |> validate_required([:hash, :type])
    |> unique_constraint(:hash)
    |> foreign_key_constraint(:block_height)
  end
end
