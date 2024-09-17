defmodule Project73.Profile.MongoRepository do
  alias Project73.Utils
  require Logger
  @behaviour Project73.Profile.Repository

  @collection "profile_events"

  def save_events(id, events) do
    first_event = hd(events)
    {_, %{sequence_number: version}} = first_event

    events =
      events
      |> Enum.map(&Utils.Mongo.flatten_event_type/1)
      |> Enum.map(&Utils.Mongo.remove_struct_field/1)

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
          |> Enum.map(&Utils.Mongo.parse_keys_to_atoms/1)
          |> Enum.map(&Utils.Mongo.to_typed_event/1)

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
end
