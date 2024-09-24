defmodule Project73.Utils.Validator do
  use Gettext, backend: Project73Web.Gettext

  def new() do
    %{}
  end

  def field(%{} = validator, field, validator_fns) do
    validator
    |> Map.put_new(field, [])
    |> Map.update!(field, &(validator_fns ++ &1))
  end

  def string(value) when is_bitstring(value), do: :ok
  def string(_), do: {:error, :invalid_type}

  def min_size(size) do
    fn
      value when is_bitstring(value) and byte_size(value) < size -> {:error, {:too_short, size}}
      value when is_list(value) and length(value) < size -> {:error, {:too_short, size}}
      _ -> :ok
    end
  end

  def is_not_empty(nil), do: {:error, :empty}
  def is_not_empty(""), do: {:error, :empty}
  def is_not_empty([]), do: {:error, :empty}
  def is_not_empty(_), do: :ok

  def apply(%{} = validator, params) do
    result =
      params
      |> Enum.reduce(%{}, fn {field, value}, acc ->
        validators = Map.get(validator, field, [])

        errors =
          validators
          |> Enum.map(fn validator_fn ->
            validator_fn.(value)
          end)
          |> Enum.filter(fn
            {:error, _} -> true
            _ -> false
          end)
          |> Enum.map(fn {:error, code} -> code end)

        case errors do
          [] -> acc
          _ -> Map.put(acc, field, errors)
        end
      end)

    case Kernel.map_size(result) do
      0 -> {:ok, params}
      _ -> {:error, {:validation, result}}
    end
  end

  def translate({:too_short, size}), do: gettext("Too short, minimum size is %{size}", size: size)
  def translate(:empty), do: gettext("Can't be empty")
  def translate(:invalid_type), do: gettext("Invalid type")

  def translate(map) when is_map(map) do
    map
    |> Enum.map(fn {field, errors} ->
      {field, Enum.map(errors, &translate/1)}
    end)
  end
end
