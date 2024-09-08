defmodule Project73.Auction.InMemoryRepostory do
  @behaviour Project73.Auction.Repostory

  def save_events(id, events) do
    # get current events
    old_events = :ets.take(:events, id)
    all_events = old_events ++ events
    :ets.insert(:events, {id, all_events})

    :ok
  end

  def load_aggregate(id) do
    :ets.new(:events, [:set, :protected, :named_table])

    case :ets.lookup(:events, id) do
      [{^id, events}] ->
        aggregate =
          Project73.Auction.Aggregate.empty()
          |> Project73.Auction.Aggregate.apply(events)

        {:ok, aggregate}

      [] ->
        {:ok}
    end
  end
end
