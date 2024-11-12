defmodule Project73.Auction.Actor do
  use GenServer
  require Logger
  alias Project73.Auction.Aggregate

  @type t :: %__MODULE__{aggregate: Aggregate.t()}
  defstruct [:aggregate]

  @repository Application.compile_env(:project_73, :auction_repository)
  @notifier Application.compile_env(:project_73, :auction_notifier)

  def init(id) do
    GenServer.cast(self(), {:load, id})
    {:ok, %__MODULE__{aggregate: Aggregate.empty()}}
  end

  def start_link(id) do
    GenServer.start_link(__MODULE__, id, name: via_tuple(id))
  end

  defp via_tuple(id) do
    {:via, Registry, {:auction_registry, id}}
  end
end
