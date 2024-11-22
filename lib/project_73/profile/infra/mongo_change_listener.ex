defmodule Project73.Profile.Infra.MongoChangeListener do
  use Task
  require Logger

  def start_link(_) do
    Task.start_link(&listen/0)
  end

  defp listen() do
    Logger.info("Listening for changes")

    stream = Mongo.watch_collection(:mongo, "profile_events", [])

    Enum.each(stream, fn doc -> Logger.debug("Received change: #{inspect(doc)}") end)
  end
end
