defmodule Project73Web.ProfileUpdateLive do
  require Logger
  alias Project73Web.I18n
  alias Project73.Shared.Address
  alias Project73.Profile.Domain.Command
  alias Project73.Profile
  use Project73Web, :live_view

  def mount(_params, _session, socket) do
    profile = socket.assigns.current_user
    Logger.debug("Profile loaded: #{inspect(profile)}")
    {:ok, pid} = Profile.Domain.Actor.get_or_create(profile.id)

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
           "address_country" => profile.address && profile.address.country,
           "address_city" => profile.address && profile.address.city,
           "address_postal_code" => profile.address && profile.address.postal_code,
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
          "address_country" => country,
          "address_city" => city,
          "address_postal_code" => postal_code,
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

    case Profile.Domain.Actor.update_profile(socket.assigns.actor_pid, cmd) do
      :ok ->
        {:noreply, redirect(socket, to: ~p"/")}

      {:error, {:validation, errors}} ->
        translated_errors = I18n.translate_errors(errors)

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
            field={@form[:address_country]}
            class="bg-gray-700 text-gray-100 border-gray-600 focus:border-indigo-500 focus:ring-indigo-500"
          />
          <.input
            label="City"
            field={@form[:address_city]}
            class="bg-gray-700 text-gray-100 border-gray-600 focus:border-indigo-500 focus:ring-indigo-500"
          />
          <.input
            label="Postal Code"
            field={@form[:address_postal_code]}
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
