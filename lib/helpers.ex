defmodule Itauynab.Helpers do
  @doc ~S"""
  Parses the amount from a string.
  ex: "R$ 1.234,56" -> 123456

  ## Examples

      iex> Itauynab.Helpers.parse_amount("R$ 1.234,56")
      123456

  """
  @spec parse_amount(String.t()) :: integer()
  def parse_amount(str_amount) do
    str_amount
    |> String.replace(~r/[^0-9]/, "")
    |> String.to_integer()
  end
end
