defmodule GloboTicketDemo do
  @moduledoc false

  alias GloboTicket.Promotions.Venues

  def setup do
    setup_venues()
  end

  def setup_venues do
    Enum.each(1..100, fn _ ->
      Venues.Controls.Venue.generate() |> Venues.Handlers.Commands.save_venue()
    end)
  end
end
