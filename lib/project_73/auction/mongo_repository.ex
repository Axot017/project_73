defmodule Project73.Auction.MongoRepository do
  alias Project73.Profile.Event
  alias Project73.Utils
  use Project73.Utils.Json
  require Logger

  @behaviour Project73.Auction.Repository

  @collection "auction_events"

  def save_events(id, events) do
    Logger.debug(%{message: "Saving auction events", events: events, id: id})
    first_event = hd(events)
    %{sequence_number: version} = first_event

    events =
      events
      |> Enum.map(fn event -> Utils.Json.serialize(event, &map_from_struct/1) end)

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
        Logger.error(%{
          message: "Failed to save auction events",
          reason: reason,
          id: id
        })

        {:error, reason}
    end
  end

  def load_aggregate(id) do
    result =
      Mongo.find(:mongo, @collection, %{"_id" => %BSON.Regex{pattern: "^#{id}", options: "i"}})

    case result do
      {:error, reason} ->
        Logger.error(%{
          message: "Failed to load auction aggregate",
          reason: reason,
          id: id
        })

        {:error, reason}

      cursor ->
        events =
          cursor
          |> Enum.map(&Map.get(&1, "events"))
          |> List.flatten()
          |> Enum.map(fn event -> Utils.Json.deserialize(event, &map_to_struct/1) end)

        if Enum.empty?(events) do
          :ok
        else
          aggregate =
            Project73.Profile.Aggregate.empty()
            |> Project73.Profile.Aggregate.apply(events)

          Logger.debug(%{message: "Loaded auction aggregate", aggregate: aggregate})

          {:ok, aggregate}
        end
    end
  end

  mapping do
    type("auction_created", Event.Created)
    include(Project73.Shared.Mapper)
  end
end
