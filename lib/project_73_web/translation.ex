defmodule Project73Web.Translation do
  use Gettext, backend: Project73Web.Gettext

  def translate_error(map) when is_map(map) do
    map
    |> Enum.map(fn {field, errors} ->
      {field, Enum.map(errors, &translate_error/1)}
    end)
  end

  def translate_error({:min_length_not_reached, min}),
    do: gettext("Too short, minimum size is %{size}", size: min)

  def translate_error({:max_length_exceeded, max}),
    do: gettext("Too long, maximum size is %{size}", size: max)

  def translate_error(:empty), do: gettext("Can't be empty")

  def translate_error(_), do: gettext("Invalid value")
end
