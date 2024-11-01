defmodule Project73Web.Plug.CheckProfile do
  use Phoenix.VerifiedRoutes,
    router: Project73Web.Router,
    endpoint: Project73Web.Endpoint

  require Logger

  import Phoenix.Controller

  import Plug.Conn

  alias Project73.Profile

  def init(opts), do: opts

  def call(%Plug.Conn{assigns: %{current_user: profile}} = conn, _opts) do
    need_setup = Profile.Aggregate.needs_setup(profile)

    current_path = conn.request_path

    profile_update_path = ~p"/profile/update"

    case {need_setup, current_path} do
      {true, ^profile_update_path} ->
        conn

      {true, _} ->
        conn
        |> redirect(to: profile_update_path)
        |> halt()

      {false, _} ->
        need_payment_account = Profile.Aggregate.needs_payment_account(profile)

        case need_payment_account do
          true -> create_payment_account(conn, profile)
          false -> conn
        end
    end
  end

  def call(conn, _opts) do
    conn
  end

  defp create_payment_account(conn, profile) do
    {:ok, pid} = Profile.Supervisor.get_actor(profile.id)

    case Profile.Actor.create_payment_account(pid) do
      :ok ->
        conn

      _ ->
        conn
        # TODO: redirect to error page
        |> redirect(to: ~p"/profile/update")
        |> halt()
    end
  end
end
