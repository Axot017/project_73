defmodule Project73.Utils.MappingGenerator do
  defmacro event_mapping(event_module, event_name) do
    quote do
      defp map_event(%unquote(event_module){} = event),
        do:
          event
          |> Map.put(:__type__, unquote(event_name))
          |> Map.delete(:__struct__)

      defp map_event(%{__type__: unquote(event_name)} = event),
        do:
          event
          |> Map.put(:__struct__, unquote(event_module))
          |> Map.delete(:__type__)
    end
  end
end
