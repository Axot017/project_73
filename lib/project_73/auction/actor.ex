defmodule Project73.Auction.Actor do
  use GenServer
  require Logger
  alias Project73.Auction.Aggregate
  alias Project73.Auction.Command

  @type t :: %__MODULE__{aggregate: Aggregate.t()}
  defstruct [:aggregate]

  @repository Application.compile_env(:project_73, :auction_repository)
  # @notifier Application.compile_env(:project_73, :auction_notifier)

  def init(id) do
    GenServer.cast(self(), {:load, id})
    {:ok, %__MODULE__{aggregate: Aggregate.empty()}}
  end

  def start_link(id) do
    GenServer.start_link(__MODULE__, id, name: via_tuple(id))
  end

  def create(pid, %Command.Create{} = cmd) do
    GenServer.call(pid, {:create, cmd})
  end

  defp via_tuple(id) do
    {:via, Registry, {:auction_registry, id}}
  end

  def handle_call({:create, %Command.Create{} = cmd}, _from, state) do
    with {:ok, events} <-
           Aggregate.handle_command(state.aggregate, cmd),
         :ok <- @repository.save_events(cmd.id, events) do
      new_state = Aggregate.apply(state.aggregate, events)
      {:reply, :ok, %__MODULE__{aggregate: new_state}}
    else
      {:error, _} = error ->
        {:reply, error, state}
    end
  end
end
