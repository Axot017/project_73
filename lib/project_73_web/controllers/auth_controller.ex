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
    id = auth.uid
    email = auth.info.email
    provider = Atom.to_string(auth.provider)
    provider_id = Project73.Profile.Aggregate.provider_id(provider, id)

    with {:ok, pid} <- Project73.Profile.Supervisor.get_actor(provider_id),
         :ok <- Project73.Profile.Actor.create(pid, provider_id, provider, email) do
      success(conn, provider_id)
    else
      {:error, :already_created} ->
        success(conn, provider_id)

      {:error, reason} ->
        Logger.error("Failed to get profile: #{inspect(reason)}")

        conn
        |> put_flash(:error, "Failed to authenticate.")
        |> redirect(to: "/")
    end
  end

  defp success(conn, provider_id) do
    conn
    |> put_flash(:info, "Successfully authenticated.")
    |> put_session(:current_user, provider_id)
    |> configure_session(renew: true)
    |> redirect(to: "/auction")
  end
end
