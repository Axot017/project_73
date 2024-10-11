defmodule Project73.Profile.MongoRepository do
  require Project73.Utils.MappingGenerator, as: MappingGenerator
  alias Project73.Profile.Event
  alias Project73.Utils
  require Logger
  @behaviour Project73.Profile.Repository

  @collection "profile_events"

  def save_events(id, events) do
    first_event = hd(events)
    {_, %{sequence_number: version}} = first_event

    events =
      events
      |> Enum.map(&map_event/1)
      |> Enum.map(&Utils.Mongo.serialize/1)

    result =
      Mongo.insert_one(
        :mongo,
        @collection,
        %{
          _id: "#{id}/#{version}",
          events: events
        }
      )

    case result do
      {:ok, _} ->
        :ok

      {:error, reason} ->
        Logger.error("Failed to save events: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def load_aggregate(id) do
    result =
      Mongo.find(:mongo, @collection, %{"_id" => %BSON.Regex{pattern: "^#{id}", options: "i"}})

    case result do
      {:error, reason} ->
        Logger.error("Failed to load aggregate: #{inspect(reason)}")
        {:error, reason}

      cursor ->
        events =
          cursor
          |> Enum.map(&Map.get(&1, "events"))
          |> List.flatten()
          |> Enum.map(&Utils.Mongo.deserialize/1)
          |> Enum.map(&map_event/1)

        if Enum.empty?(events) do
          :ok
        else
          aggregate =
            Project73.Profile.Aggregate.empty()
            |> Project73.Profile.Aggregate.apply(events)

          Logger.debug("Loaded aggregate #{inspect(aggregate)}")
          {:ok, aggregate}
        end
    end
  end

  MappingGenerator.event_mapping(Event.Created, "profile_created")
  MappingGenerator.event_mapping(Event.FirstNameChanged, "first_name_changed")
  MappingGenerator.event_mapping(Event.LastNameChanged, "last_name_changed")
  MappingGenerator.event_mapping(Event.UsernameChanged, "username_changed")
  MappingGenerator.event_mapping(Event.AddressChanged, "address_changed")
  MappingGenerator.event_mapping(Event.PaymentAccountUpdated, "payment_account_updated")
end
