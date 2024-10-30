defmodule Project73.Utils.Mongo do
  def deserialize(%{"__type__" => "DateTime", "__value__" => value}) do
    DateTime.from_iso8601(value) |> elem(1)
  end

  def deserialize(%{__struct__: _} = struct), do: struct

  def deserialize(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {String.to_atom(k), deserialize(v)} end)
  end

  def deserialize(list) when is_list(list), do: Enum.map(list, &deserialize/1)
  def deserialize(value), do: value

  def serialize(%DateTime{} = datetime),
    do: %{"__type__" => "DateTime", "__value__" => DateTime.to_iso8601(datetime)}

  def serialize(struct) when is_struct(struct), do: struct |> Map.from_struct() |> serialize()

  def serialize(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {k, serialize(v)} end)
  end

  def serialize(value), do: value
end
