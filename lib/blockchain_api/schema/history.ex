defmodule BlockchainAPI.Schema.History do
  import Ecto.Changeset
  use Ecto.Schema

  @fields [:height, :name, :score, :alpha, :beta, :delta]

  @derive {Jason.Encoder, only: @fields}
  schema "history" do
    field :height, :integer
    field :name, :string
    field :score, :float
    field :alpha, :float
    field :beta, :float
    field :delta, :float

    timestamps()
  end

  @doc false
  def changeset(history, attrs) do
    history
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> unique_constraint(:unique_height_name)
  end
end

