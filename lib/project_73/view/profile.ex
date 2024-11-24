defmodule Project73.View.Profile do
  use Ecto.Schema

  @primary_key false

  schema "profiles" do
    field :id, :string
    field :provider, :string
    field :email, :string
    field :username, :string
    field :first_name, :string
    field :last_name, :string
    field :country, :string
    field :city, :string
    field :postal_code, :string
    field :address_line1, :string
    field :address_line2, :string
    field :avatar_url, :string
    field :payment_account_id, :string
    field :wallet_balance, :decimal
    field :created_at, :utc_datetime
    field :updated_at, :utc_datetime
    field :version, :integer
  end
end
