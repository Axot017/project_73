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
    Logger.debug("Auth details: #{inspect(auth)}")

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
        |> redirect(to: ~p"/")
    end
  end

  def delete(conn, _params) do
    conn
    |> delete_session(:current_user)
    |> put_flash(:info, "Logged out.")
    |> redirect(to: ~p"/auction")
  end

  defp success(conn, user_id) do
    conn
    |> put_flash(:info, "Successfully authenticated.")
    |> put_session(:user_id, user_id)
    |> configure_session(renew: true)
    |> redirect(to: ~p"/auction")
  end
end
