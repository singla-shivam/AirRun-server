defmodule AirRunWeb.Utilities do
  alias Ecto.Changeset
  alias AirRunWeb.ErrorHelpers

  def translate_errors(changeset) do
    Changeset.traverse_errors(changeset, &ErrorHelpers.translate_error/1)
  end
end
