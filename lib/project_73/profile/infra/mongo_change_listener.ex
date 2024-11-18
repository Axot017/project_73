defmodule Project73.Profile.Infra.MongoChangeListener do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    Logger.info("Starting MongoChangeListener")
    {:ok, %{}}
  end
end
