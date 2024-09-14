defmodule Project73.Profile.Repository do
  @callback save_events(String.t(), list(Project73.Profile.Event.Created.t())) ::
              :ok | {:error, term()}

  @callback load_aggregate(String.t()) ::
              {:ok, Project73.Profile.Aggregate.t()} | :ok | {:error, term()}
end
