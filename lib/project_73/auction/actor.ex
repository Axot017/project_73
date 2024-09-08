defmodule Project73.Auction.Actor do
  use GenServer
  require Logger
  alias Project73.Auction.Aggregate

  defstruct [:aggregate]

  @repository Application.compile_env(:project_73, :auction_repository)
  @notifier Application.compile_env(:project_73, :auction_notifier)

  def create(pid, name, initial_price) do
    GenServer.call(pid, {:create, name, initial_price})
  end

  def bid(pid, bidder, price) do
    GenServer.call(pid, {:bid, bidder, price})
  end

  def get(pid) do
    GenServer.call(pid, :get)
  end

  def start_link(auction_id) do
    GenServer.start_link(__MODULE__, auction_id, name: via_tuple(auction_id))
  end

  defp via_tuple(auction_id) do
    {:via, Registry, {:auction_registry, auction_id}}
  end

  def init(id) do
    GenServer.cast(self(), {:load, id})
    {:ok, %__MODULE__{aggregate: Aggregate.new(id)}}
  end

  def handle_cast({:load, id}, state) do
    case @repository.load_aggregate(id) do
      {:ok, aggregate} ->
        Logger.debug("Loaded aggregate #{inspect(aggregate)}")
        {:noreply, %__MODULE__{aggregate: aggregate}}

      _ ->
        Logger.info("No aggregate found for #{id}")
        {:noreply, state}
    end
  end

  def handle_call({:create, name, initial_price}, _from, state) do
    with {:ok, events} <- Aggregate.create(state.aggregate, name, initial_price),
         :ok <- @repository.save_events(state.aggregate.id, events) do
      new_state = Aggregate.apply(state.aggregate, events)
      {:reply, :ok, %__MODULE__{aggregate: new_state}}
    else
      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  def handle_call({:bid, bidder, amount}, _from, state) do
    with {:ok, events} <- Aggregate.bid(state.aggregate, bidder, amount),
         :ok <- @repository.save_events(state.aggregate.id, events) do
      new_state = Aggregate.apply(state.aggregate, events)
      @notifier.auction_updated(state.aggregate.id, {:new_bid, amount})
      {:reply, :ok, %__MODULE__{aggregate: new_state}}
    else
      {:error, _} = error -> {:reply, error, state}
    end
  end

  def handle_call(:get, _from, state) do
    {:reply, state.aggregate, state}
  end
end
