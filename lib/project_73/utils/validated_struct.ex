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

    validation_fn = generate_validation_function(name, fields)

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

  defp generate_validation_function(struct_name, fields) do
    quote do
      def validate(%unquote(struct_name){} = struct) do
        result =
          Project73.Utils.ValidatedStruct.Validator.validate_struct(
            struct,
            unquote(generate_field_validators(fields))
          )

        case result do
          :ok -> {:ok, struct}
          {:error, errors} -> {:error, errors}
        end
      end
    end
  end

  defp generate_field_validators(fields) do
    for {name, type, _opts} <- fields do
      case type do
        @any_type ->
          quote do
            {unquote(name), []}
          end

        @string_type ->
          quote do
            {unquote(name), [&Project73.Utils.ValidatedStruct.Validator.string/1]}
          end

        _ ->
          quote do
            {unquote(name), []}
          end
      end
    end
  end

  defmodule Validator do
    def validate_struct(struct, field_validators) do
      field_validators
      |> Enum.reduce(:ok, fn {field, validators}, acc ->
        case {acc, validate_field(struct, field, validators)} do
          {:ok, :ok} -> :ok
          {{:error, errors}, :ok} -> {:error, errors}
          {:ok, {:error, errors}} -> {:error, errors}
          {{:error, errors1}, {:error, errors2}} -> {:error, errors1 ++ errors2}
        end
      end)
    end

    def validate_field(struct, field, validators) do
      result =
        case Map.get(struct, field) do
          nil ->
            {:error, :missing_field}

          value ->
            validators
            |> Enum.reduce(:ok, fn validator, acc ->
              case {acc, validator.(value)} do
                {:ok, :ok} -> :ok
                {{:error, errors}, :ok} -> {:error, errors}
                {:ok, {:error, error}} -> {:error, [error]}
                {{:error, errors}, {:error, error}} -> {:error, errors ++ [error]}
              end
            end)
        end

      case result do
        :ok -> :ok
        {:error, errors} -> {:error, {:field, field, errors}}
      end
    end

    def validate_list(list, validators) do
      list
      |> Enum.with_index(0)
      |> Enum.reduce(:ok, fn {value, index}, acc ->
        result =
          validators
          |> Enum.reduce(:ok, fn validator, acc ->
            case {acc, validator.(value)} do
              {:ok, :ok} -> :ok
              {{:error, errors}, :ok} -> {:error, errors}
              {:ok, {:error, errors}} -> {:error, errors}
              {{:error, errors1}, {:error, errors2}} -> {:error, errors1 ++ errors2}
            end
          end)

        case result do
          :ok -> :ok
          {:error, errors} -> {:error, {:index, index, errors}}
        end

        case {acc, result} do
          {:ok, :ok} -> :ok
          {{:error, errors}, :ok} -> {:error, errors}
          {:ok, {:error, errors}} -> {:error, errors}
          {{:error, errors1}, {:error, errors2}} -> {:error, errors1 ++ errors2}
        end
      end)
    end

    def string(value) when is_bitstring(value), do: :ok
    def string(_), do: {:error, :not_a_string}

    def integer(value) when is_integer(value), do: :ok
    def integer(_), do: {:error, :not_an_integer}

    def float(value) when is_float(value), do: :ok
    def float(_), do: {:error, :not_a_float}

    def number(value) when is_number(value), do: :ok
    def number(_), do: {:error, :not_a_number}

    def boolean(value) when value in [true, false], do: :ok
    def boolean(_), do: {:error, :not_a_boolean}
  end
end
