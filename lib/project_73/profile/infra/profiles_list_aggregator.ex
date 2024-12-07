defmodule Project73.Profile.Infra.ProfilesListAggregator do
  use GenServer
  use AMQP

  require Logger

  alias Project73.Profile.Infra.Mapper
  alias Project73.Profile.Domain.Event
  alias Project73.View.Model.Profile

  import Ecto.Query, only: [from: 2]

  @exchange "profile_events"
  @queue "profiles_list_aggregation"

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    {:ok, chan} = AMQP.Application.get_channel(:project_73_channel)
    setup_queue(chan)

    :ok = Basic.qos(chan, prefetch_count: 10)

    {:ok, _consumer_tag} = Basic.consume(chan, @queue)
    {:ok, chan}
  end

  @impl true
  def handle_info({:basic_deliver, payload, %{delivery_tag: tag}}, chan) do
    consume(chan, tag, payload)
    {:noreply, chan}
  end

  @impl true
  def handle_info({:basic_consume_ok, %{consumer_tag: _consumer_tag}}, chan) do
    {:noreply, chan}
  end

  @impl true
  def handle_info({:basic_cancel, %{consumer_tag: _consumer_tag}}, chan) do
    {:stop, :normal, chan}
  end

  @impl true
  def handle_info({:basic_cancel_ok, %{consumer_tag: _consumer_tag}}, chan) do
    {:noreply, chan}
  end

  defp consume(chan, tag, payload) do
    json_payload = Poison.decode!(payload)

    event = Project73.Utils.Json.deserialize(json_payload, &Mapper.map_to_struct/1)
    update_profile(event)

    :ok = Basic.ack(chan, tag)
  end

  defp setup_queue(chan) do
    :ok = Exchange.fanout(chan, @exchange, durable: true)

    {:ok, _} = Queue.declare(chan, @queue, durable: true)

    :ok = Queue.bind(chan, @queue, @exchange)
  end

  defp update_profile(%Event.Created{} = event) do
    Logger.debug("Saving profile created event: #{inspect(event)}")
    timestamp = DateTime.truncate(event.timestamp, :second)

    Project73.Repo.insert(%Profile{
      id: event.id,
      provider: event.provider,
      email: event.email,
      created_at: timestamp,
      updated_at: timestamp,
      wallet_balance: Decimal.new(0),
      version: event.sequence_number
    })
  end

  defp update_profile(%Event.UsernameChanged{} = event) do
    Logger.debug("Saving username changed event: #{inspect(event)}")
    timestamp = DateTime.truncate(event.timestamp, :second)

    {1, _} =
      from(p in Profile,
        where: p.id == ^event.id,
        update: [
          set: [
            username: ^event.username,
            version: ^event.sequence_number,
            updated_at: ^timestamp
          ]
        ]
      )
      |> Project73.Repo.update_all([])
  end

  defp update_profile(%Event.FirstNameChanged{} = event) do
    Logger.debug("Saving first name changed event: #{inspect(event)}")
    timestamp = DateTime.truncate(event.timestamp, :second)

    {1, _} =
      from(p in Profile,
        where: p.id == ^event.id,
        update: [
          set: [
            first_name: ^event.first_name,
            version: ^event.sequence_number,
            updated_at: ^timestamp
          ]
        ]
      )
      |> Project73.Repo.update_all([])
  end

  defp update_profile(%Event.LastNameChanged{} = event) do
    Logger.debug("Saving last name changed event: #{inspect(event)}")
    timestamp = DateTime.truncate(event.timestamp, :second)

    {1, _} =
      from(p in Profile,
        where: p.id == ^event.id,
        update: [
          set: [
            last_name: ^event.last_name,
            version: ^event.sequence_number,
            updated_at: ^timestamp
          ]
        ]
      )
      |> Project73.Repo.update_all([])
  end

  defp update_profile(%Event.AddressChanged{} = event) do
    Logger.debug("Saving address changed event: #{inspect(event)}")
    timestamp = DateTime.truncate(event.timestamp, :second)

    {1, _} =
      from(p in Profile,
        where: p.id == ^event.id,
        update: [
          set: [
            address_line1: ^event.address.line1,
            address_line2: ^event.address.line2,
            city: ^event.address.city,
            country: ^event.address.country,
            postal_code: ^event.address.postal_code,
            version: ^event.sequence_number,
            updated_at: ^timestamp
          ]
        ]
      )
      |> Project73.Repo.update_all([])
  end

  defp update_profile(event) do
    Logger.error("Unknown event", event: event)
  end
end
