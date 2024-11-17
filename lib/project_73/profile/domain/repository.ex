defmodule Project73.Profile.Domain.Repository do
  @callback save_events(String.t(), list(term())) ::
              :ok | {:error, term()}

  @callback load_aggregate(String.t()) ::
              {:ok, Project73.Profile.Domain.Aggregate.t()} | :ok | {:error, term()}
end
