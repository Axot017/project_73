defmodule Project73.Auction.Repostory do
  @callback save_events(String.t(), list()) :: :ok | {:error, term()}

  @callback load_aggregate(String.t()) ::
              {:ok, Project73.Auction.Aggregate} | :ok | {:error, term()}
end
