defmodule Project73Web.LoginLive do
  require Logger
  use Project73Web, :live_view

  def mount(_params, _session, socket) do
    case socket.assigns.current_user do
      nil ->
        {:ok, socket}

      _ ->
        Logger.info(%{
          message: "User is already logged in",
          user_id: socket.assigns.current_user.id
        })

        {:ok, socket |> push_navigate(to: ~p"/", replace: true)}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-900 flex items-center justify-center p-4">
      <div class="bg-gray-800 rounded-lg shadow-xl p-8 max-w-md w-full">
        <h2 class="text-3xl font-bold text-center text-gray-100 mb-8">Welcome</h2>
        <div class="space-y-4">
          <.redirect_button
            href={~p"/auth/facebook"}
            class="w-full bg-blue-600 hover:bg-blue-700 text-white font-semibold py-3 px-4 rounded-md transition duration-300 ease-in-out flex items-center justify-center"
          >
            <svg class="w-5 h-5 mr-2" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
              <path
                fill-rule="evenodd"
                d="M22 12c0-5.523-4.477-10-10-10S2 6.477 2 12c0 4.991 3.657 9.128 8.438 9.878v-6.987h-2.54V12h2.54V9.797c0-2.506 1.492-3.89 3.777-3.89 1.094 0 2.238.195 2.238.195v2.46h-1.26c-1.243 0-1.63.771-1.63 1.562V12h2.773l-.443 2.89h-2.33v6.988C18.343 21.128 22 16.991 22 12z"
                clip-rule="evenodd"
              />
            </svg>
            Login with Facebook
          </.redirect_button>
          <.redirect_button
            href={~p"/auth/google"}
            class="w-full bg-gray-700 hover:bg-gray-600 text-white font-semibold py-3 px-4 rounded-md transition duration-300 ease-in-out flex items-center justify-center"
          >
            <svg class="w-5 h-5 mr-2" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
              <path d="M12.545,10.239v3.821h5.445c-0.712,2.315-2.647,3.972-5.445,3.972c-3.332,0-6.033-2.701-6.033-6.032s2.701-6.032,6.033-6.032c1.498,0,2.866,0.549,3.921,1.453l2.814-2.814C17.503,2.988,15.139,2,12.545,2C7.021,2,2.543,6.477,2.543,12s4.478,10,10.002,10c8.396,0,10.249-7.85,9.426-11.748L12.545,10.239z" />
            </svg>
            Login with Google
          </.redirect_button>
        </div>
      </div>
    </div>
    """
  end
end
