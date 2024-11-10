defmodule Project73.Utils.Json do
  defmacro __using__(_) do
    quote do
      import Project73.Utils.Json, only: [mapping: 1]
    end
  end

  defmacro mapping(do: block) do
    types = extract_types(block)

    from_struct_mappers =
      types
      |> Enum.filter(fn type -> elem(type, 0) == :type end)
      |> Enum.map(&generate_from_struct_mapper/1)

    from_struct_includes =
      types
      |> Enum.filter(fn type -> elem(type, 0) == :include end)
      |> Enum.map(fn {:include, module} -> module end)
      |> generate_from_stuct_include()

    to_struct_mappers =
      types
      |> Enum.filter(fn type -> elem(type, 0) == :type end)
      |> Enum.map(&generate_to_struct_mapper/1)

    to_struct_includes =
      types
      |> Enum.filter(fn type -> elem(type, 0) == :include end)
      |> Enum.map(fn {:include, module} -> module end)
      |> generate_to_stuct_include()

    quote do
      unquote(from_struct_mappers)

      unquote(from_struct_includes)

      unquote(to_struct_mappers)

      unquote(to_struct_includes)
    end
  end

  defp generate_from_struct_mapper({:type, name, type}) do
    quote do
      def map_from_struct(%unquote(type){} = event) do
        event
        |> Map.put(:__type__, unquote(name))
        |> Map.from_struct()
      end
    end
  end

  defp generate_to_struct_mapper({:type, name, type}) do
    quote do
      def map_to_struct(%{__type__: unquote(name)} = event),
        do:
          event
          |> Map.put(:__struct__, unquote(type))
          |> Map.delete(:__type__)
    end
  end

  defp generate_to_stuct_include(modules) do
    functions_calls =
      Enum.reduce(modules, quote(do: event), fn module, acc ->
        quote do
          unquote(module).map_to_struct(unquote(acc))
        end
      end)

    quote do
      def map_to_struct(event) do
        unquote(functions_calls)
      end
    end
  end

  defp generate_from_stuct_include(modules) do
    functions_calls =
      Enum.reduce(modules, quote(do: event), fn module, acc ->
        quote do
          unquote(module).map_from_struct(unquote(acc))
        end
      end)

    quote do
      def map_from_struct(event) do
        unquote(functions_calls)
      end
    end
  end

  defp extract_types(block) do
    Macro.prewalk(block, [], fn
      {:type, _, [name, type]} = node, acc -> {node, [{:type, name, type} | acc]}
      {:include, _, [module]} = node, acc -> {node, [{:include, module} | acc]}
      node, acc -> {node, acc}
    end)
    |> elem(1)
    |> Enum.reverse()
  end

  @type_field "__type__"
  @value_field "value"
  @date_time_type "date_time"

  def deserialize(%{@type_field => @date_time_type, @value_field => value}, _) do
    {:ok, date_time, _} = value |> DateTime.from_iso8601()
    date_time
  end

  def deserialize(map, struct_mapper) when is_map(map) do
    Map.new(map, fn {k, v} -> {String.to_atom(k), deserialize(v, struct_mapper)} end)
    |> struct_mapper.()
  end

  def deserialize(list, struct_mapper) when is_list(list),
    do: Enum.map(list, &deserialize(&1, struct_mapper))

  def deserialize(value, _), do: value

  def serialize(%DateTime{} = date_time, _) do
    %{
      @type_field => @date_time_type,
      @value_field => date_time |> DateTime.to_iso8601()
    }
  end

  def serialize(struct, struct_mapper) when is_struct(struct),
    do: struct_mapper.(struct) |> serialize(struct_mapper)

  def serialize(map, struct_mapper) when is_map(map) do
    Map.new(map, fn {k, v} -> {k, serialize(v, struct_mapper)} end)
  end

  def serialize(list, struct_mapper) when is_list(list),
    do: Enum.map(list, &serialize(&1, struct_mapper))

  def serialize(value, _), do: value

  def to_map(struct) when is_struct(struct) do
    struct
    |> Map.from_struct()
  end

  def to_map(map) when is_map(map) do
    map
  end
end
