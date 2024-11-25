defmodule Project73Web.LiveUserInjector do
  import Phoenix.Component
  import Phoenix.LiveView
  alias Project73.Profile
  use Project73Web, :verified_routes
  require Logger

  def on_mount(:public, _params, %{"user_id" => user_id}, socket) when is_binary(user_id) do
    socket =
      case socket.assigns do
        %{current_user: _current_user} ->
          socket

        _ ->
          case get_profile(user_id) do
            nil -> socket
            user -> socket |> assign(:current_user, user)
          end
      end

    {:cont, socket}
  end

  def on_mount(:public, _params, _session, socket) do
    {:cont, socket |> assign(:current_user, nil)}
  end

  def on_mount(:authorized, _params, %{"user_id" => user_id}, socket) when is_binary(user_id) do
    case socket.assigns do
      %{current_user: _current_user} ->
        {:cont, socket}

      _ ->
        case get_profile(user_id) do
          nil -> {:halt, socket |> redirect(to: ~p"/login")}
          user -> {:cont, socket |> assign(:current_user, user)}
        end
    end
  end

  defp get_profile(user_id) when is_binary(user_id) do
    case Profile.Domain.Actor.get_or_create(user_id) do
      {:ok, pid} -> Profile.Domain.Actor.get_profile(pid)
      _ -> nil
    end
  end
end
