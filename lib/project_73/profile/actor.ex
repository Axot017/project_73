defmodule Project73.Profile.Actor do
  use GenServer
  alias Project73.Profile.Command
  alias Project73.Profile.Aggregate
  require Logger

  @type t :: %__MODULE__{aggregate: Aggregate.t()}

  defstruct [:aggregate]

  @repository Application.compile_env(:project_73, :profile_repository)
  @payment_provider Application.compile_env(:project_73, :payment_provider)

  def init(id) do
    GenServer.cast(self(), {:load, id})
    {:ok, %__MODULE__{aggregate: Aggregate.empty()}}
  end

  def start_link(auction_id) do
    GenServer.start_link(__MODULE__, auction_id, name: via_tuple(auction_id))
  end

  def create(pid, %Command.Create{} = cmd) do
    GenServer.call(pid, {:create, cmd})
  end

  def update_profile(pid, %Command.Update{} = cmd) do
    GenServer.call(pid, {:update, cmd})
  end

  def create_payment_account(pid) do
    GenServer.call(pid, {:create_payment_account})
  end

  def request_deposit(pid, amount) do
    GenServer.call(pid, {:request_deposit, amount})
  end

  def get_profile(pid) do
    GenServer.call(pid, :get_profile)
  end

  defp via_tuple(user_id) do
    {:via, Registry, {:profile_registry, user_id}}
  end

  def handle_call({:create, %Command.Create{} = cmd}, _from, state) do
    with {:ok, events} <-
           Aggregate.handle_command(state.aggregate, cmd),
         _ <- Logger.debug("Events: #{inspect(events)}"),
         :ok <- @repository.save_events(cmd.id, events) do
      new_state = Aggregate.apply(state.aggregate, events)
      {:reply, :ok, %__MODULE__{aggregate: new_state}}
    else
      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  def handle_call({:update, %Command.Update{} = cmd}, _from, state) do
    with {:ok, events} <- Aggregate.handle_command(state.aggregate, cmd),
         :ok <- @repository.save_events(state.aggregate.id, events),
         new_state = Aggregate.apply(state.aggregate, events) do
      {:reply, :ok, %__MODULE__{aggregate: new_state}}
    else
      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  def handle_call({:create_payment_account}, _from, state) do
    with {:ok, payment_account_id} <- @payment_provider.create_customer(state.aggregate),
         {:ok, events} <-
           Aggregate.handle_command(state.aggregate, %Command.UpdatePaymentAccount{
             payment_account_id: payment_account_id
           }),
         :ok <- @repository.save_events(state.aggregate.id, events) do
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

  def handle_call({:request_deposit, amount}, _from, state) do
    result =
      @payment_provider.create_payment_intent(%{
        amount: Decimal.to_integer(amount),
        customer_id: state.aggregate.payment_account_id,
        user_id: state.aggregate.id
      })

    {:reply, result, state}
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
