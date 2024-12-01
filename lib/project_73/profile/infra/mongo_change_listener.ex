defmodule Project73.Profile.Infra.MongoChangeListener do
  require Logger

  use Task, restart: :permanent

  @exchange "profile_events"
  @cursor_collection "cdc_cursors"
  @profile_cursor_key "profile_cursor"

  def start_link(_) do
    Task.start_link(&listen/0)
  end

  defp listen() do
    Logger.info("Listening for changes")

    cursor = load_cursor()

    stream = Mongo.watch_collection(:mongo, "profile_events", [], nil, start_after: cursor)

    {:ok, chan} = AMQP.Application.get_channel(:project_73_channel)

    init_exchange(chan)

    Enum.each(stream, &handle_change(&1, chan))
  end

  defp handle_change(
         %{
           "_id" => cursor,
           "operationType" => "insert",
           "fullDocument" => %{"events" => events}
         },
         %AMQP.Channel{} = chan
       )
       when is_list(events) do
    events
    |> Enum.each(&send_event(chan, &1))

    save_cursor(cursor)
  end

  defp save_cursor(cursor) do
    Mongo.update_one!(
      :mongo,
      @cursor_collection,
      %{
        _id: @profile_cursor_key
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

  defp load_cursor() do
    result = Mongo.find_one(:mongo, @cursor_collection, %{"_id" => @profile_cursor_key})

    case result do
      %{"cursor" => cursor} ->
        Logger.debug("Loaded cursor: #{inspect(cursor)}")
        cursor

      nil ->
        Logger.debug("No cursor found")
        nil

      {:error, reason} ->
        Logger.error("Failed to load cursor: #{inspect(reason)}")
        raise reason
    end
  end

  defp init_exchange(%AMQP.Channel{} = chan) do
    Logger.debug("Declaring exchange: #{@exchange}")
    AMQP.Exchange.declare(chan, @exchange, :fanout, durable: true)
  end

  defp send_event(%AMQP.Channel{} = chan, event) do
    Logger.debug("Sending profile event to RabbitMQ: #{inspect(event)}")
    encoded = Poison.encode!(event)
    :ok = AMQP.Basic.publish(chan, @exchange, "", encoded)
  end
end
