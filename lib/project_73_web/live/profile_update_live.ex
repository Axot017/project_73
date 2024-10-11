defmodule Project73Web.ProfileUpdateLive do
  require Logger
  alias Project73.Shared.Address
  alias Project73.Profile.Command
  alias Project73.Utils.Validator
  alias Project73.Profile
  use Project73Web, :live_view

  def mount(_params, %{"current_user" => profile}, socket) do
    Logger.debug("Profile loaded: #{inspect(profile)}")
    {:ok, pid} = Profile.Supervisor.get_actor(profile.id)

    {:ok,
     socket
     |> assign(
       profile: profile,
       actor_pid: pid,
       form:
         to_form(%{
           "username" => profile.username,
           "first_name" => profile.first_name,
           "last_name" => profile.last_name,
           "country" => profile.address && profile.address.country,
           "city" => profile.address && profile.address.city,
           "postal_code" => profile.address && profile.address.postal_code,
           "address_line1" => profile.address && profile.address.line1,
           "address_line2" => profile.address && profile.address.line2
         })
     ), layout: false}
  end

  def handle_event(
        "save",
        %{
          "username" => username,
          "first_name" => first_name,
          "last_name" => last_name,
          "country" => country,
          "city" => city,
          "postal_code" => postal_code,
          "address_line1" => address_line1,
          "address_line2" => address_line2
        } = profile_form,
        socket
      ) do
    cmd = %Command.Update{
      username: username,
      first_name: first_name,
      last_name: last_name,
      address: %Address{
        country: country,
        city: city,
        postal_code: postal_code,
        line1: address_line1,
        line2: address_line2
      }
    }

    case Profile.Actor.update_profile(socket.assigns.actor_pid, cmd) do
      :ok ->
        {:noreply, redirect(socket, to: ~p"/auction")}

      {:error, {:validation, errors}} ->
        translated_errors = Validator.translate(errors)

        updated_form =
          to_form(profile_form)
          |> Map.put(:errors, translated_errors)

        {:noreply, assign(socket, form: updated_form)}
    end
  end

  def handle_event("validate", %{"_target" => targets}, socket) do
    form = socket.assigns.form

    updated_errors =
      form.errors
      |> Enum.reject(fn {field, _msg} ->
        Enum.any?(targets, fn target -> target == Atom.to_string(field) end)
      end)

    updated_form =
      form
      |> Map.put(:errors, updated_errors)

    {:noreply, assign(socket, form: updated_form)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-900 flex items-center justify-center p-4">
      <div class="bg-gray-800 rounded-lg shadow-xl p-8 max-w-md w-full">
        <h2 class="text-3xl font-bold text-center text-gray-100 mb-8">Set Up Your Account</h2>
        <.simple_form for={@form} phx-submit="save" phx-change="validate" class="space-y-6">
          <.input
            label="Username"
            field={@form[:username]}
            class="bg-gray-700 text-gray-100 border-gray-600 focus:border-indigo-500 focus:ring-indigo-500"
          />
          <.input
            label="First Name"
            field={@form[:first_name]}
            class="bg-gray-700 text-gray-100 border-gray-600 focus:border-indigo-500 focus:ring-indigo-500"
          />
          <.input
            label="Last Name"
            field={@form[:last_name]}
            class="bg-gray-700 text-gray-100 border-gray-600 focus:border-indigo-500 focus:ring-indigo-500"
          />
          <.input
            label="Country"
            field={@form[:country]}
            class="bg-gray-700 text-gray-100 border-gray-600 focus:border-indigo-500 focus:ring-indigo-500"
          />
          <.input
            label="City"
            field={@form[:city]}
            class="bg-gray-700 text-gray-100 border-gray-600 focus:border-indigo-500 focus:ring-indigo-500"
          />
          <.input
            label="Postal Code"
            field={@form[:postal_code]}
            class="bg-gray-700 text-gray-100 border-gray-600 focus:border-indigo-500 focus:ring-indigo-500"
          />
          <.input
            label="Address Line 1"
            field={@form[:address_line1]}
            class="bg-gray-700 text-gray-100 border-gray-600 focus:border-indigo-500 focus:ring-indigo-500"
          />
          <.input
            label="Address Line 2"
            field={@form[:address_line2]}
            class="bg-gray-700 text-gray-100 border-gray-600 focus:border-indigo-500 focus:ring-indigo-500"
          />
          <.button
            type="submit"
            class="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-semibold py-3 px-4 rounded-md transition duration-300 ease-in-out"
          >
            Save
          </.button>
        </.simple_form>
      </div>
    </div>
    """
  end
end
