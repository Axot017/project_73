defmodule Project73.Auction.Command do
  use Project73.Utils.ValidatedStruct
  alias Project73.Auction.Command

  @type t ::
          Command.Create.t()

  validated_struct Create do
    field :id, :string, not_empty: true
    field :title, :string, not_empty: true
    field :description, :string, not_empty: true
    field :initial_price, :decimal, gt: 0
    field :images, {:list, :string}, not_empty: true
  end

  def validate(%Command.Create{} = cmd) do
    Command.Create.validate(cmd)
  end
end
