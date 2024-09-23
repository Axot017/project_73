defmodule Project73Web.Plug.SetLanguage do
  import Plug.Conn
  require Logger

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_req_header(conn, "accept-language") do
      [] ->
        conn

      [accept_language | _] ->
        language =
          accept_language
          |> String.split(";")
          |> List.first()
          |> String.trim()
          |> String.downcase()
          |> String.split(",")
          |> List.first()
          |> String.split("-")
          |> List.first()

        Logger.info("Used language: #{language}")

        Gettext.put_locale(Project73Web.Gettext, language)

        conn
        |> put_session(:language, language)
    end
  end
end
