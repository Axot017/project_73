defmodule Project73.Profile.Infra.MongoRepository do
  alias Project73.Profile.Domain.Aggregate
  alias Project73.Profile.Infra.Mapper
  alias Project73.Utils
  use Project73.Shared.Infra.MongoAggregateRepository, collection: "profile_events"

  def serialize_event(event) do
    Utils.Json.serialize(event, &Mapper.map_from_struct/1)
  end

  def deserialize_event(event) do
    Utils.Json.deserialize(event, &Mapper.map_to_struct/1)
  end

  def create_aggregate(events) do
    Aggregate.empty()
    |> Aggregate.apply(events)
  end
end
