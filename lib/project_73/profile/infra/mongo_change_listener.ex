defmodule Project73.Profile.Infra.MongoChangeListener do
  require Logger

  use Task, restart: :permanent

  @exchange "profile_events"

  def start_link(_) do
    Task.start_link(&listen/0)
  end

  defp listen() do
    Logger.info("Listening for changes")

    stream = Mongo.watch_collection(:mongo, "profile_events", [])

    {:ok, chan} = AMQP.Application.get_channel(:project_73_channel)

    init_exchange(chan)

    Enum.each(stream, &handle_change(&1, chan))
  end

  defp handle_change(
         %{
           "_id" => _cursor,
           "operationType" => "insert",
           "fullDocument" => %{"events" => events}
         },
         %AMQP.Channel{} = chan
       )
       when is_list(events) do
    events
    |> Enum.each(&send_event(chan, &1))
  end

  defp init_exchange(%AMQP.Channel{} = chan) do
    AMQP.Exchange.declare(chan, @exchange, :fanout, durable: true)
  end

  defp send_event(%AMQP.Channel{} = chan, event) do
    encoded = Poison.encode!(event)
    :ok = AMQP.Basic.publish(chan, @exchange, "", encoded)
  end
end
