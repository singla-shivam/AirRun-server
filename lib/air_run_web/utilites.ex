defmodule AirRunWeb.Utilities do
  alias Ecto.Changeset
  alias AirRunWeb.ErrorHelpers

  def translate_errors(changeset) do
    Changeset.traverse_errors(changeset, &ErrorHelpers.translate_error/1)
  end

  def parse_callback_body(body) do
    if body["_json"] != nil do
      Poison.decode!(body["_json"])
    else
      body
    end
  end
end
