defmodule Project73.Profile.Infra.MongoChangeListener do
  use Task, restart: :permanent
  alias Project73.Profile.Infra.Mapper
  alias Project73.Profile.Domain.Event
  alias Project73.View.Model.Profile
  require Logger
  import Ecto.Query, only: [from: 2]

  def start_link(_) do
    Task.start_link(&listen/0)
  end

  defp listen() do
    Logger.info("Listening for changes")

    stream = Mongo.watch_collection(:mongo, "profile_events", [])

    Enum.each(stream, &handle_change/1)
  end

  defp handle_change(%{
         "_id" => _cursor,
         "operationType" => "insert",
         "fullDocument" => %{"events" => events}
       })
       when is_list(events) do
    events =
      events
      |> Enum.map(fn event -> Project73.Utils.Json.deserialize(event, &Mapper.map_to_struct/1) end)

    Enum.each(events, &save/1)
  end

  defp save(%Event.Created{} = event) do
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

  defp save(%Event.UsernameChanged{} = event) do
    Logger.debug("Saving username changed event: #{inspect(event)}")
    timestamp = DateTime.truncate(event.timestamp, :second)

    {1, _} =
      from(p in Profile,
        where: p.id == ^event.id and p.version == ^event.sequence_number - 1,
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

  defp save(%Event.FirstNameChanged{} = event) do
    Logger.debug("Saving first name changed event: #{inspect(event)}")
    timestamp = DateTime.truncate(event.timestamp, :second)

    {1, _} =
      from(p in Profile,
        where: p.id == ^event.id and p.version == ^event.sequence_number - 1,
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

  defp save(%Event.LastNameChanged{} = event) do
    Logger.debug("Saving last name changed event: #{inspect(event)}")
    timestamp = DateTime.truncate(event.timestamp, :second)

    {1, _} =
      from(p in Profile,
        where: p.id == ^event.id and p.version == ^event.sequence_number - 1,
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

  defp save(%Event.AddressChanged{} = event) do
    Logger.debug("Saving address changed event: #{inspect(event)}")
    timestamp = DateTime.truncate(event.timestamp, :second)

    {1, _} =
      from(p in Profile,
        where: p.id == ^event.id and p.version == ^event.sequence_number - 1,
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

  defp save(event) do
    Logger.error("Unknown event", event: event)
  end
end
