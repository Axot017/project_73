defmodule Project73.Profile.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [
      {Horde.Registry, keys: :unique, name: Project73.Profile.Domain.Registry},
      {Horde.DynamicSupervisor,
       name: Project73.Profile.Domain.Supervisor, strategy: :one_for_one},
      {Highlander, {Project73.Profile.Infra.MongoChangeListener, []}}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
