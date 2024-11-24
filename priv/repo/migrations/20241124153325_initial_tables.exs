defmodule Project73.Repo.Migrations.InitialTables do
  use Ecto.Migration

  def up do
    create table("profiles", primary_key: false) do
      add :id, :string, primary_key: true, null: false
      add :provider, :string, null: false
      add :email, :string, null: false
      add :username, :string, null: true
      add :first_name, :string, null: true
      add :last_name, :string, null: true
      add :country, :string, null: true
      add :city, :string, null: true
      add :postal_code, :string, null: true
      add :address_line1, :string, null: true
      add :address_line2, :string, null: true
      add :avatar_url, :string, null: true
      add :payment_account_id, :string, null: true
      add :wallet_balance, :decimal, null: false
      add :created_at, :utc_datetime, null: false
      add :updated_at, :utc_datetime, null: false
      add :version, :integer, null: false
    end
  end

  def down do
    drop table("profiles")
  end
end
