defmodule GloboTicketWeb.VenueLive.Index do
  use GloboTicketWeb, :live_view

  alias GloboTicket.Promotions.Venues

  @impl true
  def mount(_params, _session, socket) do
    socket = assign(socket, :venues, list_venues())
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket = apply_action(socket, socket.assigns.live_action, params)

    {:noreply, socket}
  end

  defp apply_action(socket, :index, params) do
    uuid = params["uuid"] || Identifier.Uuid.generate()

    socket
    |> assign(:page_title, "Listing Venues")
    |> assign(:venue, nil)
    |> assign(:uuid, uuid)
  end

  defp apply_action(socket, :new, %{"uuid" => uuid}) do
    socket
    |> assign(:page_title, "New Venue")
    |> assign(:venue, %Venues.VenueInfo{uuid: uuid})
    |> assign(:uuid, :new)
  end

  defp list_venues do
    Venues.VenueQueries.list_venues()
  end
end