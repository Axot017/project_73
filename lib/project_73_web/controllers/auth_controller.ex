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
        |> redirect(to: "/")
    end
  end

  def delete(conn, _params) do
    conn
    |> delete_session(:current_user)
    |> put_flash(:info, "Logged out.")
    |> redirect(to: "/auction")
  end

  defp success(conn, user_id) do
    with {:ok, pid} <- Project73.Profile.Supervisor.get_actor(user_id),
         profile <- Project73.Profile.Actor.get_profile(pid) do
      Logger.debug("Profile loaded: #{inspect(profile)}")

      res =
        conn
        |> put_flash(:info, "Successfully authenticated.")
        |> put_session(:current_user, profile)
        |> configure_session(renew: true)

      if profile.username == nil do
        res |> redirect(to: ~p"/profile/update")
      else
        res |> redirect(to: "/auction")
      end
    else
      {:error, reason} ->
        Logger.error("Failed to get profile: #{inspect(reason)}")

        conn
        |> put_flash(:error, "Failed to authenticate.")
        |> redirect(to: "/")
    end
  end

  def refresh(conn, _params) do
    profile = get_session(conn, :current_user)

    success(conn, profile.id)
  end
end
