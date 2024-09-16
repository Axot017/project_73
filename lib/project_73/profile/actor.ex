defmodule Project73.Profile.Actor do
  use GenServer
  alias Project73.Profile.Aggregate
  require Logger

  @type t :: %__MODULE__{aggregate: Aggregate.t()}

  defstruct [:aggregate]

  @repository Application.compile_env(:project_73, :profile_repository)

  def init(id) do
    GenServer.cast(self(), {:load, id})
    {:ok, %__MODULE__{aggregate: Aggregate.empty()}}
  end

  def start_link(auction_id) do
    GenServer.start_link(__MODULE__, auction_id, name: via_tuple(auction_id))
  end

  def create(pid, id, provider, email) do
    GenServer.call(pid, {:create, id, provider, email})
  end

  def get_profile(pid) do
    GenServer.call(pid, :get_profile)
  end

  def update_profile(pid, data) do
    GenServer.call(pid, {:update_profile, data})
  end

  defp via_tuple(user_id) do
    {:via, Registry, {:profile_registry, user_id}}
  end

  def handle_call({:create, id, provider, email}, _from, state) do
    with {:ok, events} <- Aggregate.create(state.aggregate, id, provider, email),
         :ok <- @repository.save_events(id, events) do
      new_state = Aggregate.apply(state.aggregate, events)
      {:reply, :ok, %__MODULE__{aggregate: new_state}}
    else
      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  def handle_call({:update_profile, data}, _from, state) do
    events = Aggregate.update_profile(state.aggregate, data)

    with :ok <- @repository.save_events(state.aggregate.id, events) do
      new_state = Aggregate.apply(state.aggregate, events)
      {:reply, :ok, %__MODULE__{aggregate: new_state}}
    else
      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  def handle_call(:get_profile, _from, state) do
    {:reply, state.aggregate, state}
  end

  def handle_cast({:load, id}, state) do
    case @repository.load_aggregate(id) do
      {:ok, aggregate} ->
        Logger.debug("Loaded aggregate #{inspect(aggregate)}")
        {:noreply, %__MODULE__{aggregate: aggregate}}

      :ok ->
        Logger.info("No aggregate found for #{id}")
        {:noreply, state}

      {:error, _} ->
        Logger.error("Failed to load aggregate for #{id}")
        {:stop, :failed_to_load_aggregate, state}
    end
  end
end
