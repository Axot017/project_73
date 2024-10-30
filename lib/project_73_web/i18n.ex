defmodule Project73Web.I18n do
  use Gettext, backend: Project73Web.Gettext

  def translate_errors(errors) when is_list(errors) do
    Enum.map(errors, &translate_error/1)
  end

  defp translate_error({field, errors}) when is_tuple(field) and is_list(errors) do
    field_name = field |> Tuple.to_list() |> Enum.join("_")
    [error | _] = errors
    {String.to_atom(field_name), translate_error(error)}
  end

  defp translate_error({:min_length_not_reached, min}),
    do: gettext("Too short, minimum size is %{size}", size: min)

  defp translate_error({:max_length_exceeded, max}),
    do: gettext("Too long, maximum size is %{size}", size: max)

  defp translate_error(:empty), do: gettext("Can't be empty")

  defp translate_error(_), do: gettext("Invalid value")
end
