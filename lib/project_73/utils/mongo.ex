defmodule Project73.Utils.Mongo do
  def flatten_event_type({type, data}) do
    Map.put(data, :type, type)
  end

  def remove_struct_field(data) do
    Map.delete(data, :__struct__)
  end

  def to_typed_event(%{} = data) do
    {String.to_atom(data.type), Map.delete(data, :type)}
  end

  def parse_keys_to_atoms(%DateTime{} = datetime), do: datetime
  def parse_keys_to_atoms(%{__struct__: _} = struct), do: struct

  def parse_keys_to_atoms(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {String.to_atom(k), parse_keys_to_atoms(v)} end)
  end

  def parse_keys_to_atoms(list) when is_list(list), do: Enum.map(list, &parse_keys_to_atoms/1)
  def parse_keys_to_atoms(value), do: value
end
