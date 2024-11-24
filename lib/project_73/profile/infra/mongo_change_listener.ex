defmodule Project73.Profile.Infra.MongoChangeListener do
  use Task
  alias Project73.Profile.Infra.Mapper
  alias Project73.Profile.Domain.Event
  require Logger

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
    Logger.debug("Saving profile created event", event: event)
    timestamp = DateTime.truncate(event.timestamp, :second)

    Project73.Repo.insert(%Project73.View.Profile{
      id: event.id,
      provider: event.provider,
      email: event.email,
      created_at: timestamp,
      updated_at: timestamp,
      wallet_balance: Decimal.new(0),
      version: event.sequence_number
    })
  end
end
