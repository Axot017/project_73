defmodule Project73Web.AuthController do
  require Logger
  use Project73Web, :controller
  plug Ueberauth

  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    conn
    |> put_flash(:error, "Failed to authenticate.")
    |> redirect(to: "/")
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    email = auth.info.email

    conn
    |> put_flash(:info, "Successfully authenticated as #{email}.")
    |> put_session(:current_user, auth)
    |> configure_session(renew: true)
    |> redirect(to: "/auction")
  end
end
