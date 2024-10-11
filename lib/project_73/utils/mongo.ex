defmodule Project73.Utils.Mongo do
  def deserialize(%DateTime{} = datetime), do: datetime
  def deserialize(%{__struct__: _} = struct), do: struct

  def deserialize(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {String.to_atom(k), deserialize(v)} end)
  end

  def deserialize(list) when is_list(list), do: Enum.map(list, &deserialize/1)
  def deserialize(value), do: value

  def serialize(value), do: value
end
