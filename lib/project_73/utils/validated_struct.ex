defmodule Project73.Utils.ValidatedStruct do
  defmacro __using__(_) do
    quote do
      import Project73.Utils.ValidatedStruct, only: [validated_struct: 2]
    end
  end

  defmacro validated_struct(name, do: block) do
    fields = extract_fields(block)
    struct_def = generate_struct(name, fields)

    quote do
      unquote(struct_def)
    end
  end

  defp extract_fields(block) do
    Macro.prewalk(block, [], fn
      {:field, _, [name, type, opts]} = node, acc -> {node, [{name, type, opts} | acc]}
      {:field, _, [name, type]} = node, acc -> {node, [{name, type, []} | acc]}
      {:field, _, [name]} = node, acc -> {node, [{name, :string, []} | acc]}
      node, acc -> {node, acc}
    end)
    |> elem(1)
    |> Enum.reverse()
  end

  defp generate_struct(struct_name, fields) do
    struct_fields =
      for {name, _type, opts} <- fields do
        default = Keyword.get(opts, :default, nil)
        {name, default}
      end

    quote do
      defmodule unquote(struct_name) do
        defstruct unquote(struct_fields)
      end
    end
  end
end
