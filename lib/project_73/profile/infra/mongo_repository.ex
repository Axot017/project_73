defmodule Project73.Profile.Infra.MongoRepository do
  alias Project73.Profile.Domain.Aggregate
  alias Project73.Profile.Infra.Mapper
  alias Project73.Utils
  require Logger

  @behaviour Project73.Profile.Domain.Repository

  @collection "profile_events"

  def save_events(id, events) do
    Logger.debug("Saving profile events: #{inspect(events)}")
    first_event = hd(events)
    %{sequence_number: version} = first_event

    events =
      events
      |> Enum.map(fn event -> Utils.Json.serialize(event, &Mapper.map_from_struct/1) end)

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
          |> Enum.map(fn event -> Utils.Json.deserialize(event, &Mapper.map_to_struct/1) end)

        if Enum.empty?(events) do
          :ok
        else
          aggregate =
            Aggregate.empty()
            |> Aggregate.apply(events)

          Logger.debug("Loaded aggregate #{inspect(aggregate)}")
          {:ok, aggregate}
        end
    end
  end
end
