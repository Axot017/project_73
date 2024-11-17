defmodule Project73.Profile.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      {Horde.Registry, keys: :unique, name: :profile_registry},
      {Project73.Profile.Domain.Supervisor, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
