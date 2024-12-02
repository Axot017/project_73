defmodule Project73.Shared.Infra.MongoChangeListener do
  require Logger

  defmacro __using__(params) when is_list(params) do
    collection = Keyword.get(params, :collection)
    exchange = Keyword.get(params, :exchange)
    cursor_collection = Keyword.get(params, :cursor_collection)
    profile_cursor_key = Keyword.get(params, :profile_cursor_key)
    channel = Keyword.get(params, :channel)
    module_name = __MODULE__

    quote do
      require Logger

      use Task, restart: :permanent

      @collection unquote(collection)
      @exchange unquote(exchange)
      @cursor_collection unquote(cursor_collection)
      @profile_cursor_key unquote(profile_cursor_key)
      @channel unquote(channel)

      def start_link(_) do
        config = %{
          collection: @collection,
          exchange: @exchange,
          cursor_collection: @cursor_collection,
          profile_cursor_key: @profile_cursor_key,
          channel: @channel
        }

        Task.start_link(fn -> unquote(module_name).listen(config) end)
      end
    end
  end

  def listen(%{channel: channel, collection: collection} = config) do
    Logger.info("Listening for changes on collection: #{collection}")

    cursor = load_cursor(config)

    stream = Mongo.watch_collection(:mongo, collection, [], nil, start_after: cursor)

    {:ok, chan} = AMQP.Application.get_channel(channel)

    init_exchange(chan, config)

    Enum.each(stream, &handle_change(&1, chan, config))
  end

  defp handle_change(
         %{
           "_id" => cursor,
           "operationType" => "insert",
           "fullDocument" => %{"events" => events}
         },
         %AMQP.Channel{} = chan,
         config
       )
       when is_list(events) do
    events
    |> Enum.each(&send_event(chan, config, &1))

    save_cursor(cursor, config)
  end

  defp save_cursor(
         cursor,
         %{
           cursor_collection: cursor_collection,
           profile_cursor_key: profile_cursor_key
         }
       ) do
    Mongo.update_one!(
      :mongo,
      cursor_collection,
      %{
        _id: profile_cursor_key
      },
      %{
        "$set" => %{
          cursor: cursor,
          updated_at: DateTime.utc_now()
        }
      },
      upsert: true
    )
  end

  defp load_cursor(%{
         cursor_collection: cursor_collection,
         profile_cursor_key: profile_cursor_key,
         collection: collection
       }) do
    result = Mongo.find_one(:mongo, cursor_collection, %{"_id" => profile_cursor_key})

    case result do
      %{"cursor" => cursor} ->
        Logger.debug("Loaded cursor for collection #{collection}: #{inspect(cursor)}")
        cursor

      nil ->
        Logger.debug("No cursor found for collection #{collection}")
        nil

      {:error, reason} ->
        Logger.error("Failed to load cursor for collection #{collection}: #{inspect(reason)}")

        raise reason
    end
  end

  defp init_exchange(%AMQP.Channel{} = chan, %{exchange: exchange}) do
    Logger.debug("Declaring exchange: #{exchange}")
    AMQP.Exchange.declare(chan, exchange, :fanout, durable: true)
  end

  defp send_event(%AMQP.Channel{} = chan, %{exchange: exchange}, event) do
    Logger.debug("Sending event to RabbitMQ: #{inspect(event)}")
    encoded = Poison.encode!(event)
    :ok = AMQP.Basic.publish(chan, exchange, "", encoded)
  end
end
