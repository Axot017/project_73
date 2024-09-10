defmodule Project73.Auction.MongoRepository do
  @behaviour Project73.Auction.Repostory
  require Logger

  def save_events(id, events) do
    first_event = hd(events)
    version = first_event.sequence_number

    result =
      Mongo.insert_one(
        :mongo,
        "events",
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
      Mongo.find(:mongo, "events", %{"_id" => %BSON.Regex{pattern: "^#{id}", options: "i"}})

    case result do
      {:error, reason} ->
        Logger.error("Failed to load aggregate: #{inspect(reason)}")
        {:error, reason}

      cursor ->
        events =
          cursor
          |> Enum.map(&Map.get(&1, "events"))
          |> List.flatten()
          |> Enum.map(&map_event/1)

        if Enum.empty?(events) do
          :ok
        else
          Logger.error("Loaded events: #{inspect(events)}")
          aggregate = Project73.Auction.Aggregate.empty()

          {:ok, Project73.Auction.Aggregate.apply(aggregate, events)}
        end
    end
  end

  defp map_event(event) do
    event
    |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
    |> parse_atom_fields(~w(type)a)
  end

  defp parse_atom_fields(map, fields) do
    Enum.reduce(fields, map, fn field, acc ->
      Map.update(acc, field, nil, &String.to_atom/1)
    end)
  end
end
