defmodule Project73.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Project73Web.Telemetry,
      {DNSCluster, query: Application.get_env(:project_73, :dns_cluster_query) || :ignore},
      {Finch, name: Project73.Finch},
      {Phoenix.PubSub, name: Project73.PubSub},
      Project73Web.Endpoint,
      {Project73.Profile.Supervisor, name: Project73.Profile.Supervisor},
      {Registry, keys: :unique, name: :auction_registry},
      {Project73.Auction.Supervisor, []},
      {Mongo, Application.get_env(:project_73, :mongo) || []}
    ]

    opts = [strategy: :one_for_one, name: Project73.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    Project73Web.Endpoint.config_change(changed, removed)
    :ok
  end
end
