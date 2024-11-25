defmodule Project73.View.Repository do
  require Ecto.Query

  def find_profile_by_id(id) do
    Project73.View.Model.Profile
    |> Ecto.Query.where([p], p.id == ^id)
    |> Project73.Repo.one()
  end
end
