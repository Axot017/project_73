defmodule Project73.Utils.Validator do
  def new() do
    %{}
  end

  def field(%{} = validator, field, validator_fn) do
    validator
    |> Map.put_new(field, [])
    |> Map.update!(field, &[validator_fn | &1])
  end

  def field_not_empty(%{} = validator, field) do
    field(validator, field, fn
      nil -> {:error, :empty}
      "" -> {:error, :empty}
      [] -> {:error, :empty}
      _ -> :ok
    end)
  end

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
end
