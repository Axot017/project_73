defmodule Project73.Profile.Infra.MongoChangeListener do
  use Project73.Shared.Infra.MongoChangeListener,
    collection: "profile_events",
    exchange: "profile_events",
    cursor_collection: "cdc_cursors",
    cursor_key: "profile_cursor",
    channel: :project_73_channel
end
