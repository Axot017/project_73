defmodule Project73Web.LiveUserInjector do
  import Phoenix.Component
  import Phoenix.LiveView
  alias Project73.Profile
  use Project73Web, :verified_routes
  require Logger

  def on_mount(:public, _params, %{"user_id" => user_id}, socket) when is_binary(user_id) do
    {:cont, socket |> assign(:user_id, user_id)}
    |> include_current_user()
    |> setup_account()
    |> create_payment_account()
  end

  def on_mount(:public, _params, _session, socket) do
    {:cont, socket |> assign(:current_user, nil)}
  end

  def on_mount(:authorized, _params, %{"user_id" => user_id}, socket) when is_binary(user_id) do
    {:cont, socket |> assign(:user_id, user_id)}
    |> include_current_user()
    |> require_current_user()
    |> setup_account()
    |> create_payment_account()
  end

  def on_mount(:authorized, _params, _session, socket) do
    {:halt, socket |> redirect(to: ~p"/login")}
  end

  defp setup_account({:cont, %{view: Project73Web.ProfileUpdateLive} = socket}) do
    {:cont, socket}
  end

  defp setup_account({:cont, %{assigns: %{current_user: current_user}} = socket}) do
    need_setup = Profile.Domain.Aggregate.needs_setup(current_user)

    profile_update_path = ~p"/profile/update"

    case need_setup do
      true ->
        {:halt, socket |> redirect(to: profile_update_path)}

      false ->
        {:cont, socket}
    end
  end

  defp setup_account({:cont, socket}) do
    {:cont, socket}
  end

  defp setup_account({:halt, _conn} = res) do
    res
  end

  defp require_current_user({:cont, %{assigns: %{current_user: _current_user}} = socket}) do
    {:cont, socket}
  end

  defp require_current_user({:cont, socket}) do
    {:halt, socket |> redirect(to: ~p"/login")}
  end

  defp require_current_user({:halt, _conn} = res) do
    res
  end

  defp include_current_user({:cont, %{assigns: %{current_user: _current_user}} = socket}) do
    {:cont, socket}
  end

  defp include_current_user({:cont, %{assigns: %{user_id: user_id}} = socket}) do
    case Profile.Domain.Actor.get_or_create(user_id) do
      {:ok, pid} ->
        {:cont, socket |> assign(:current_user, Profile.Domain.Actor.get_profile(pid))}

      _ ->
        {:cont, socket}
    end
  end

  defp include_current_user(res) do
    res
  end

  defp create_payment_account({:cont, %{assigns: %{current_user: current_user}} = socket}) do
    {:ok, pid} = Profile.Domain.Actor.get_or_create(current_user.id)
    need_setup = Profile.Domain.Aggregate.needs_setup(current_user)

    case need_setup do
      true ->
        {:cont, socket}

      false ->
        case Profile.Domain.Actor.create_payment_account(pid) do
          :ok ->
            {:cont, socket}

          _ ->
            {:halt, socket |> redirect(to: ~p"/")}
        end
    end
  end

  defp create_payment_account(res) do
    res
  end
end
