defmodule Project73.Shared.Infra.MongoAggregateRepository do
  require Logger

  @callback serialize_event(term()) :: term()

  @callback deserialize_event(term()) :: term()

  @callback create_aggregate(list(term())) :: term()

  defmacro __using__(params) when is_list(params) do
    collection = Keyword.get(params, :collection)
    module_name = __MODULE__

    quote do
      @collection unquote(collection)

      @behaviour Project73.Shared.Infra.MongoAggregateRepository

      def save_events(id, events) do
        unquote(module_name).save_events(%{
          collection: @collection,
          serializer: &serialize_event/1,
          id: id,
          events: events
        })
      end

      def load_aggregate(id) do
        unquote(module_name).load_aggregate(%{
          collection: @collection,
          deserializer: &deserialize_event/1,
          aggregate_creator: &create_aggregate/1,
          id: id
        })
      end
    end
  end

  def save_events(%{
        collection: collection,
        serializer: serializer,
        id: id,
        events: events
      })
      when is_binary(collection) and
             is_function(serializer, 1) and
             is_binary(id) and
             is_list(events) do
    Logger.debug("Saving events to #{collection} collection: #{inspect(events)}")
    first_event = hd(events)
    %{sequence_number: version} = first_event

    events =
      events
      |> Enum.map(&serializer.(&1))

    result =
      Mongo.insert_one(
        :mongo,
        collection,
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

  def load_aggregate(%{
        collection: collection,
        deserializer: deserializer,
        aggregate_creator: aggregate_creator,
        id: id
      })
      when is_binary(collection) and
             is_function(deserializer, 1) and
             is_function(aggregate_creator, 1) and
             is_binary(id) do
    result =
      Mongo.find(:mongo, collection, %{"_id" => %BSON.Regex{pattern: "^#{id}", options: "i"}})

    case result do
      {:error, reason} ->
        Logger.error("Failed to load aggregate: #{inspect(reason)}")
        {:error, reason}

      cursor ->
        events =
          cursor
          |> Enum.map(&Map.get(&1, "events"))
          |> List.flatten()
          |> Enum.map(&deserializer.(&1))

        if Enum.empty?(events) do
          :ok
        else
          aggregate =
            aggregate_creator.(events)

          Logger.debug("Loaded aggregate #{inspect(aggregate)}")
          {:ok, aggregate}
        end
    end
  end
end
