defmodule BlockchainAPI.Schema.Notification do
  use Ecto.Schema
  import Ecto.Changeset

  @fields [
    :id,
    :style,
    :icon,
    :color,
    :title,
    :body,
    :share_text,
    :account_address,
    :hotspot_address,
    :hotspot_name,
    :viewed_at
  ]

  @derive {Jason.Encoder, only: @fields}

  schema "notifications" do
    field :style, :string, null: false, default: "default"
    field :icon, :string, null: true
    field :color, :string, null: true
    field :title, :map, null: false
    field :body, :map, null: false
    field :share_text, :map, null: true
    field :account_address, :string, null: false
    field :hotspot_address, :string, null: true
    field :hotspot_name, :string, null: true
    field :viewed_at, :utc_datetime, null: true

    timestamps()
  end

  @doc false
  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [
      :style,
      :icon,
      :color,
      :title,
      :body,
      :share_text,
      :account_address,
      :hotspot_address,
      :hotspot_name
    ])
    |> validate_required([:style, :title, :body, :account_address])
  end
end
