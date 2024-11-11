defmodule Project73.Auction.Event do
  alias Project73.Auction.Event

  @type t ::
          Event.Created.t()

  defmodule Created do
    @type t() :: %__MODULE__{
            id: String.t(),
            title: String.t(),
            description: String.t(),
            initial_price: Decimal.t(),
            images: [String.t()],
            timestamp: DateTime.t(),
            sequence_number: integer()
          }
    defstruct [:id, :title, :description, :initial_price, :images, :timestamp, :sequence_number]
  end
end
