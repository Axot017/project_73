defmodule Project73.Shared.Address do
  use Project73.Utils.ValidatedStruct

  validated_struct do
    field :country, :string, not_empty: true
    field :city, :string, not_empty: true
    field :postal_code, :string, not_empty: true
    field :line1, :string, not_empty: true
    field :line2, :string
  end
end
