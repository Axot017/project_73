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
    user = %{id: provider_id}

    with {:ok, pid} <- Project73.Profile.Supervisor.get_actor(provider_id),
         :ok <- Project73.Profile.Actor.create(pid, provider_id, provider, email),
         user <- Project73.Profile.Actor.get_profile(pid) do
      success(conn, user)
    else
      {:error, :already_created} ->
        success(conn, user)

      {:error, reason} ->
        Logger.error("Failed to get profile: #{inspect(reason)}")

        conn
        |> put_flash(:error, "Failed to authenticate.")
        |> redirect(to: "/")
    end
  end

  def delete(conn, _params) do
    conn
    |> delete_session(:current_user)
    |> put_flash(:info, "Logged out.")
    |> redirect(to: "/auction")
  end

  defp success(conn, user) do
    res =
      conn
      |> put_flash(:info, "Successfully authenticated.")
      |> put_session(:current_user, user)
      |> configure_session(renew: true)

    if not Map.has_key?(user, :username) do
      res |> redirect(to: ~p"/profile/setup")
    else
      res |> redirect(to: "/auction")
    end
  end
end
