defmodule Project73Web.Plug.FetchProfile do
  import Plug.Conn
  alias Project73.Profile

  def init(default), do: default

  def call(conn, _opts) do
    case get_session(conn, :user_id) do
      nil ->
        conn

      user_id ->
        case Profile.Supervisor.get_actor(user_id) do
          {:ok, pid} ->
            user = Profile.Actor.get_profile(pid)
            assign(conn, :current_user, user)

          _ ->
            conn
        end
    end
  end
end
