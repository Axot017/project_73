defmodule Project73.Utils.ValidatedStruct do
  @any_type :any
  @atom_type :atom
  @string_type :string
  @integer_type :integer
  @float_type :float
  @number_type :number
  @boolean_type :boolean
  @list_type :list
  @map_type :map

  defmacro __using__(_) do
    quote do
      import Project73.Utils.ValidatedStruct, only: [validated_struct: 2]
    end
  end

  defmacro validated_struct(name, do: block) do
    fields = extract_fields(block)

    struct_fields =
      for {name, _type, opts} <- fields do
        default = Keyword.get(opts, :default, nil)
        {name, default}
      end

    type_def = generate_types(name, fields)

    validation_fn = generate_validation_function(name)

    quote =
      quote do
        defmodule unquote(name) do
          unquote(type_def)
          defstruct unquote(struct_fields)

          unquote(validation_fn)
        end
      end

    IO.inspect(Macro.to_string(quote), label: "Generated code")
    quote
  end

  defp extract_fields(block) do
    Macro.prewalk(block, [], fn
      {:field, _, [name, type, opts]} = node, acc -> {node, [{name, type, opts} | acc]}
      {:field, _, [name, type]} = node, acc -> {node, [{name, type, []} | acc]}
      {:field, _, [name]} = node, acc -> {node, [{name, @any_type, []} | acc]}
      node, acc -> {node, acc}
    end)
    |> elem(1)
    |> Enum.reverse()
  end

  defp generate_types(struct_name, fields) do
    field_types =
      for {name, type, _opts} <- fields do
        {name, convert_type(type)}
      end

    quote do
      @type t() :: %unquote(struct_name){unquote_splicing(field_types)}
    end
  end

  defp convert_type(@any_type), do: quote(do: any())
  defp convert_type(@atom_type), do: quote(do: atom())
  defp convert_type(@string_type), do: quote(do: String.t())
  defp convert_type(@integer_type), do: quote(do: integer())
  defp convert_type(@float_type), do: quote(do: float())
  defp convert_type(@number_type), do: quote(do: number())
  defp convert_type(@boolean_type), do: quote(do: boolean())
  defp convert_type({@list_type, inner_type}), do: quote(do: [unquote(convert_type(inner_type))])

  defp convert_type({@map_type, key_type, value_type}),
    do: quote(do: %{unquote(convert_type(key_type)) => unquote(convert_type(value_type))})

  defp convert_type(atom) when is_atom(atom), do: raise("Unknown type: #{inspect(atom)}")
  defp convert_type(other), do: quote(do: unquote(other))

  defp generate_validation_function(struct_name) do
    validate_fn_name =
      struct_name
      |> get_last_submodule()
      |> Macro.underscore()
      |> (&"validate_#{&1}").()
      |> String.to_atom()

    quote do
      def unquote(validate_fn_name)(%unquote(struct_name){} = struct) do
        IO.inspect(struct, label: "Validating struct")
        :ok
      end
    end
  end

  defp get_last_submodule(name) do
    name |> Macro.to_string() |> String.split(".") |> List.last()
  end
end
