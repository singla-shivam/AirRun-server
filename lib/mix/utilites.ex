defmodule Mix.Utilities do
  def capitalize_keys(data) do
    for {key, value} <- data, into: %{} do
      key =
        String.upcase(key)
        |> String.replace("-", "_")

      value = if is_map(value), do: capitalize_keys(value), else: value
      {key, value}
    end
  end
end
