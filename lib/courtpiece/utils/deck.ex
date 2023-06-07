defmodule CourtPieceWeb.Utils.Deck do
  @moduledoc false

  def suits do
    [:hearts, :spades, :clubs, :diamonds]
  end

  def cards do
    [:ace, 2, 3, 4, 5, 6, 7, 8, 9, 10, :jack, :queen, :king]
  end

  def shuffle do
    deck = for number <- cards(), suit <- suits(), do: {suit, number}
    deck = for card <- deck, do: {:crypto.strong_rand_bytes(5), card}
    deck = Enum.sort(deck)
    for {_, card} <- deck, do: card
  end
end
