defmodule Project73Web.Plug.CheckProfile do
  use Phoenix.VerifiedRoutes,
    router: Project73Web.Router,
    endpoint: Project73Web.Endpoint

  import Phoenix.Controller

  import Plug.Conn

  alias Project73.Profile

  def init(opts), do: opts

  def call(%Plug.Conn{assigns: %{current_user: profile}} = conn, _opts) do
    need_setup = Profile.Aggregate.needs_setup(profile)

    case need_setup do
      true ->
        conn
        |> redirect(to: ~p"/profile/update")
        |> halt()

      false ->
        need_payment_account = Profile.Aggregate.needs_payment_account(profile)

        case need_payment_account do
          true ->
            {:ok, _pid} = Profile.Supervisor.get_actor(profile.id)

            # TODO: create payment account
            conn

          false ->
            conn
        end
    end
  end

  def call(conn, _opts) do
    conn
  end
end
