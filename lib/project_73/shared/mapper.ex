defmodule Project73.Shared.Mapper do
  use Project73.Utils.Json

  mapping do
    type("address", Project73.Shared.Address)
  end
end
