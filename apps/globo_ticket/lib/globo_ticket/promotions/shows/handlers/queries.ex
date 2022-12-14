defmodule GloboTicket.Promotions.Shows.Handlers.Queries do
  @moduledoc false

  use GloboTicket.QueryHandler

  alias GloboTicket.Promotions.Shows
  alias GloboTicket.Promotions.Shows.Projection
  alias GloboTicket.Promotions.Shows.Records
  alias GloboTicket.Promotions.Venues

  def list_shows(act_id) do
    show_query = from Records.Show, where: [act_uuid: ^act_id]

    venue_query =
      Venues.Records.Venue
      |> Venues.Query.snapshots_query()

    records =
      show_query
      |> present
      |> Repo.all()
      |> Repo.preload(venue: venue_query)

    Enum.map(records, &Projection.apply_all(%Shows.Show{}, &1))
  end

  defp present(query) do
    from(record in query,
      left_join: cancellation in assoc(record, :cancellation),
      where: is_nil(cancellation.id)
    )
  end
end
