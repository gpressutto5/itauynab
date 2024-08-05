defmodule ItauynabTest do
  use ExUnit.Case
  doctest Itauynab
  alias Itauynab.Itau

  test "greets the world" do
    assert Itauynab.hello() == :world
  end

  test "parses the card json to ynab format" do
    # assert Itau.parse_credit_card_transactions() == :world
  end
end
