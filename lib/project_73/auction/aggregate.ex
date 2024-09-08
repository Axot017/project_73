defmodule Project73.Auction.Aggregate do
  defstruct [:id, :name, :current_price, :highest_bidder, :last_bid_at, :created_at]

  def empty() do
    %__MODULE__{}
  end

  def new(id) do
    %__MODULE__{id: id}
  end

  def create(%__MODULE__{} = self, name, initial_price) do
    case self.created_at do
      nil ->
        {:ok,
         [
           %{
             id: self.id,
             type: :auction_created,
             name: name,
             initial_price: initial_price,
             timestamp: DateTime.utc_now()
           }
         ]}

      _ ->
        {:error, :already_created}
    end
  end

  def bid(%__MODULE__{} = self, bidder, amount) do
    case amount > self.current_price do
      true ->
        {:ok, [%{type: :bid, bidder: bidder, amount: amount, timestamp: DateTime.utc_now()}]}

      false ->
        {:error, :price_too_low}
    end
  end

  def apply(%__MODULE__{} = self, events) do
    Enum.reduce(events, self, fn event, acc ->
      apply_event(acc, event)
    end)
  end

  defp apply_event(
         %__MODULE__{} = self,
         %{
           type: :bid
         } = event
       ) do
    %__MODULE__{
      self
      | current_price: event.amount,
        highest_bidder: event.bidder,
        last_bid_at: event.timestamp
    }
  end

  defp apply_event(
         %__MODULE__{} = self,
         %{
           type: :auction_created
         } = event
       ) do
    %__MODULE__{
      self
      | name: event.name,
        current_price: event.initial_price,
        created_at: event.timestamp
    }
  end
end
