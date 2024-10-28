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
      import Project73.Utils.ValidatedStruct, only: [validated_struct: 2, validated_struct: 1]
    end
  end

  defmacro validated_struct(do: block) do
    fields = extract_fields(block)

    module = __CALLER__.module

    type_def = generate_types(module, fields)

    validation_fn = generate_validation_function(module, fields)

    struct_fields =
      for {name, _type, opts} <- fields do
        default = Keyword.get(opts, :default, nil)
        {name, default}
      end

    quote do
      unquote(type_def)
      defstruct unquote(struct_fields)

      unquote(validation_fn)
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

    quote do
      defmodule unquote(name) do
        unquote(type_def)
        defstruct unquote(struct_fields)

        unquote(validation_fn)
      end
    end
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
    fields |> Enum.map(&generate_validators/1)
  end

  defp generate_validators({name, type, opts}) do
    type_validators =
      generate_type_validators(type)

    detailed_validators =
      generate_detailed_validators(opts)

    is_optional = Keyword.get(opts, :optional, false)
    should_dive = Keyword.get(opts, :dive, false)

    needed_validators =
      case should_dive do
        false ->
          quote do
            unquote(type_validators) ++ unquote(detailed_validators)
          end

        true ->
          quote do
            unquote(type_validators) ++
              unquote(detailed_validators) ++
              [&unquote(extract_module_from_type(type)).validate/1]
          end
      end

    quote do
      {unquote(name), {unquote(is_optional), unquote(needed_validators)}}
    end
  end

  defp extract_module_from_type({{:., _, [{:__aliases__, _, mod_parts}, :t]}, _, _}) do
    Module.concat(mod_parts)
  end

  defp generate_type_validators(@any_type) do
    quote do
      []
    end
  end

  defp generate_type_validators(@string_type) do
    quote do
      [&Project73.Utils.ValidatedStruct.Validator.string/1]
    end
  end

  defp generate_type_validators(@float_type) do
    quote do
      [&Project73.Utils.ValidatedStruct.Validator.float/1]
    end
  end

  defp generate_type_validators(@number_type) do
    quote do
      [&Project73.Utils.ValidatedStruct.Validator.number/1]
    end
  end

  defp generate_type_validators(@integer_type) do
    quote do
      [&Project73.Utils.ValidatedStruct.Validator.integer/1]
    end
  end

  defp generate_type_validators(@boolean_type) do
    quote do
      [&Project73.Utils.ValidatedStruct.Validator.boolean/1]
    end
  end

  defp generate_type_validators({@list_type, _item_type}) do
    quote do
      [&Project73.Utils.ValidatedStruct.Validator.list/1]
    end
  end

  defp generate_type_validators({@map_type, _key_type, _value_type}) do
    quote do
      [&Project73.Utils.ValidatedStruct.Validator.map/1]
    end
  end

  defp generate_type_validators(@atom_type) do
    quote do
      [&Project73.Utils.ValidatedStruct.Validator.atom/1]
    end
  end

  # Some custom type
  defp generate_type_validators(_type) do
    quote do
      []
    end
  end

  defp generate_detailed_validators(opts) do
    opts
    |> Enum.filter(fn {key, _} -> key not in [:default, :optional, :dive] end)
    |> Enum.map(fn {key, value} -> get_validator_fn(key, value) end)
  end

  defp get_validator_fn(:gt, min) do
    quote do
      fn value -> Project73.Utils.ValidatedStruct.Validator.greater_than(value, unquote(min)) end
    end
  end

  defp get_validator_fn(:gte, min) do
    quote do
      fn value ->
        Project73.Utils.ValidatedStruct.Validator.greater_than_or_equal(value, unquote(min))
      end
    end
  end

  defp get_validator_fn(:lt, max) do
    quote do
      fn value -> Project73.Utils.ValidatedStruct.Validator.less_than(value, unquote(max)) end
    end
  end

  defp get_validator_fn(:lte, max) do
    quote do
      fn value ->
        Project73.Utils.ValidatedStruct.Validator.less_than_or_equal(value, unquote(max))
      end
    end
  end

  defp get_validator_fn(:eq, expected) do
    quote do
      fn value -> Project73.Utils.ValidatedStruct.Validator.equal(value, unquote(expected)) end
    end
  end

  defp get_validator_fn(:neq, expected) do
    quote do
      fn value ->
        Project73.Utils.ValidatedStruct.Validator.not_equal(value, unquote(expected))
      end
    end
  end

  defp get_validator_fn(:not_empty, true) do
    quote do
      fn value -> Project73.Utils.ValidatedStruct.Validator.not_empty(value) end
    end
  end

  defp get_validator_fn(:max_length, max) do
    quote do
      fn value -> Project73.Utils.ValidatedStruct.Validator.max_length(value, unquote(max)) end
    end
  end

  defp get_validator_fn(:min_length, min) do
    quote do
      fn value -> Project73.Utils.ValidatedStruct.Validator.min_length(value, unquote(min)) end
    end
  end

  defmodule Validator do
    def validate_struct(struct, field_validators) do
      field_validators
      |> Enum.reduce(:ok, fn {field, {is_optional, validators}}, acc ->
        add_errors(acc, validate_field(struct, field, is_optional, validators))
      end)
    end

    defp add_errors(:ok, :ok), do: :ok
    defp add_errors({:error, errors}, :ok) when is_list(errors), do: {:error, errors}
    defp add_errors({:error, error}, :ok), do: {:error, [error]}
    defp add_errors(:ok, {:error, errors}) when is_list(errors), do: {:error, errors}
    defp add_errors(:ok, {:error, error}), do: {:error, [error]}

    defp add_errors({:error, errors1}, {:error, errors2})
         when is_list(errors1) and is_list(errors2),
         do: {:error, errors1 ++ errors2}

    defp add_errors({:error, errors}, {:error, error}) when is_list(errors),
      do: {:error, [error | errors]}

    defp add_errors({:error, error}, {:error, errors}) when is_list(errors),
      do: {:error, [error | errors]}

    defp add_errors({:error, error1}, {:error, error2}), do: {:error, [error1, error2]}

    def validate_field(struct, field, is_optional, validators) do
      result =
        case Map.get(struct, field) do
          nil ->
            case is_optional do
              true -> :ok
              false -> {:error, [:missing_field]}
            end

          value ->
            validators
            |> Enum.reduce(:ok, &add_errors(&2, &1.(value)))
        end

      case result do
        :ok -> :ok
        {:error, errors} -> {:error, flatten_errors({field}, errors)}
      end
    end

    defp flatten_errors(field, [{{inner_field}, errors}])
         when is_tuple(field) and is_atom(inner_field) and is_list(errors) do
      new_field = Tuple.append(field, inner_field)

      errors |> Enum.map(&flatten_errors(new_field, &1))
    end

    defp flatten_errors(field, error) when is_tuple(field) and is_atom(error) do
      {field, [error]}
    end

    defp flatten_errors(field, error) when is_tuple(field) and is_tuple(error) do
      {field, [error]}
    end

    defp flatten_errors(field, errors) when is_tuple(field) and is_list(errors) do
      {field, errors}
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
              {{:error, errors1}, {:error, errors2}} -> {:error, errors2 ++ errors1}
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
          {{:error, errors1}, {:error, errors2}} -> {:error, errors2 ++ errors1}
        end
      end)
    end

    def string(value) when is_binary(value), do: :ok
    def string(_), do: {:error, :not_a_string}

    def integer(value) when is_integer(value), do: :ok
    def integer(_), do: {:error, :not_an_integer}

    def float(value) when is_float(value), do: :ok
    def float(_), do: {:error, :not_a_float}

    def number(value) when is_number(value), do: :ok
    def number(_), do: {:error, :not_a_number}

    def boolean(value) when value in [true, false], do: :ok
    def boolean(_), do: {:error, :not_a_boolean}

    def list(value) when is_list(value), do: :ok
    def list(_), do: {:error, :not_a_list}

    def map(value) when is_map(value), do: :ok
    def map(_), do: {:error, :not_a_map}

    def atom(value) when is_atom(value), do: :ok
    def atom(_), do: {:error, :not_an_atom}

    def less_than(value, max) when value < max, do: :ok
    def less_than(_, max), do: {:error, {:greater_than_max, max}}

    def less_than_or_equal(value, max) when value <= max, do: :ok
    def less_than_or_equal(_, max), do: {:error, {:greater_than_max, max}}

    def greater_than(value, min) when value > min, do: :ok
    def greater_than(_, min), do: {:error, {:less_than_min, min}}

    def greater_than_or_equal(value, min) when value >= min, do: :ok
    def greater_than_or_equal(_, min), do: {:error, {:less_than_min, min}}

    def equal(value, expected) when value == expected, do: :ok
    def equal(value, _), do: {:error, {:not_equal, value}}

    def not_equal(value, expected) when value != expected, do: :ok
    def not_equal(value, _), do: {:error, {:equal, value}}

    def not_empty(list) when is_list(list) and length(list) > 0, do: :ok
    def not_empty(map) when is_map(map) and map_size(map) > 0, do: :ok

    def not_empty(string) when is_binary(string) do
      case String.trim(string) do
        "" -> {:error, :empty}
        _ -> :ok
      end
    end

    def not_empty(_), do: {:error, :empty}

    def max_length(list, max) when is_list(list) and length(list) <= max, do: :ok
    def max_length(map, max) when is_map(map) and map_size(map) <= max, do: :ok

    def max_length(string, max) when is_binary(string) do
      case String.length(string) do
        len when len <= max -> :ok
        _ -> {:error, {:max_length_exceeded, max}}
      end
    end

    def max_length(_, max), do: {:error, {:max_length_exceeded, max}}

    def min_length(list, min) when is_list(list) and length(list) >= min, do: :ok
    def min_length(map, min) when is_map(map) and map_size(map) >= min, do: :ok

    def min_length(string, min) when is_binary(string) do
      case String.length(string) do
        len when len >= min -> :ok
        _ -> {:error, {:min_length_not_reached, min}}
      end
    end

    def min_length(_, min), do: {:error, {:min_length_not_reached, min}}
  end
end
