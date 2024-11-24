defmodule Project73.Profile.Infra.Mapper do
  alias Project73.Profile.Domain.Event
  use Project73.Utils.Json

  mapping do
    type("profile_created", Event.Created)
    type("first_name_changed", Event.FirstNameChanged)
    type("last_name_changed", Event.LastNameChanged)
    type("username_changed", Event.UsernameChanged)
    type("address_changed", Event.AddressChanged)
    type("payment_account_updated", Event.PaymentAccountUpdated)
    include(Project73.Shared.Mapper)
  end
end
