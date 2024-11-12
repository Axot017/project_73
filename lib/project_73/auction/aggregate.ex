defmodule Project73.Auction.Aggregate do
  alias Project73.Auction.Event
  alias Project73.Auction.Command
  require Logger

  @type t :: %__MODULE__{
          id: String.t(),
          title: String.t(),
          description: String.t(),
          images: [String.t()],
          current_price: Decimal.t(),
          highest_bidder: String.t() | nil,
          last_bid_at: DateTime.t() | nil,
          created_at: DateTime.t(),
          version: integer()
        }
  defstruct [
    :id,
    :title,
    :description,
    :images,
    :current_price,
    :highest_bidder,
    :last_bid_at,
    :created_at,
    :version
  ]

  def empty() do
    %__MODULE__{}
  end

  def handle_command(%__MODULE__{} = self, cmd) do
    case Command.validate(cmd) do
      {:ok, cmd} ->
        handle_valid_command(self, cmd)

      {:error, errors} ->
        Logger.info("Invalid auciton command: #{inspect(errors)}")
        {:error, {:validation, errors}}
    end
  end

  defp handle_valid_command(%__MODULE__{} = self, %Command.Create{} = cmd) do
    case self.created_at do
      nil ->
        {:ok,
         [
           %Event.Created{
             id: cmd.id,
             title: cmd.title,
             description: cmd.description,
             timestamp: DateTime.utc_now(),
             sequence_number: 1
           }
         ]}

      _ ->
        {:error, :already_exists}
    end
  end

  def apply(self, events) do
    Enum.reduce(events, self, &apply_event(&2, &1))
  end

  defp apply_event(%__MODULE__{}, %Event.Created{} = event) do
    %__MODULE__{
      id: event.id,
      title: event.title,
      description: event.description,
      images: event.images,
      current_price: event.initial_price,
      highest_bidder: nil,
      last_bid_at: nil,
      created_at: event.timestamp,
      version: event.sequence_number
    }
  end
end
