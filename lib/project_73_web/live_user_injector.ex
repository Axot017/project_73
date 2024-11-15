defmodule Project73Web.LiveUserInjector do
  import Phoenix.Component
  import Phoenix.LiveView
  alias Project73.Profile
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
    socket
  end

  def on_mount(:authorized, _params, %{"user_id" => user_id}, socket) when is_binary(user_id) do
    case socket.assigns do
      %{current_user: _current_user} ->
        {:cont, socket}

      _ ->
        case get_profile(user_id) do
          nil -> {:halt, socket |> redirect(to: "/login")}
          user -> {:cont, socket |> assign(:current_user, user)}
        end
    end
  end

  defp get_profile(user_id) when is_binary(user_id) do
    case Profile.Supervisor.get_actor(user_id) do
      {:ok, pid} -> Profile.Actor.get_profile(pid)
      _ -> nil
    end
  end
end

