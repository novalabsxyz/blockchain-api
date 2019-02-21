defmodule BlockchainAPI.Explorer.Block do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Phoenix.Param, key: :height}
  @derive {Jason.Encoder, only: [:id, :height, :hash, :round, :time]}
  schema "blocks" do
    field :hash, :string, null: false
    field :round, :integer, null: false
    field :time, :integer, null: false
    field :height, :integer, null: false

    timestamps()
  end

  @doc false
  def changeset(block, attrs) do
    block
    |> cast(attrs, [:hash, :height, :round, :time])
    |> validate_required([:hash, :height, :round, :time])
    |> unique_constraint(:hash)
    |> unique_constraint(:height)
  end
end
