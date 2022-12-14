defmodule GloboTicketWeb.ActLiveTest do
  use GloboTicketWeb.ConnCase

  import Phoenix.LiveViewTest
  import Phoenix.Resource.Assertions

  alias GloboTicket.Promotions.Acts
  alias GloboTicket.Promotions.Contents
  alias GloboTicket.Promotions.Shows
  alias GloboTicket.Promotions.Venues
  alias Verity.Clock
  alias Verity.Identifier

  @form_identifier "#act-form"

  defp create_act(_context) do
    act = Acts.Controls.Act.example()
    {:ok, _act} = Acts.Handlers.Commands.save_act(act)
    %{act: act}
  end

  defp create_venue(_context) do
    venue = Venues.Controls.Venue.example()
    {:ok, _venue} = Venues.Handlers.Commands.save_venue(venue)
    %{venue: venue}
  end

  defp schedule_show(%{act: act, venue: venue}) do
    {:ok, _show} =
      Shows.Handlers.Commands.schedule_show(act.id, venue.id, Clock.Controls.DateTime.example())

    [show] = Shows.Handlers.Queries.list_shows(act.id)

    %{show: show}
  end

  describe "Index" do
    setup [:create_act]

    test "lists all acts", %{conn: conn, act: act} do
      {:ok, _index_live, html} = list_acts(conn)

      html
      |> assert_html("h1", "Listing Acts")
      |> assert_resource(:act, :title, act)
    end

    test "saves new act", %{conn: conn} do
      act_id = Identifier.Uuid.Controls.Random.example()
      {:ok, index_live, _html} = list_acts(conn, id: act_id)

      index_live
      |> new_act()
      |> assert_html("h2", "New Act")

      assert_patch(index_live, Routes.act_index_path(conn, :new, act_id))

      index_live
      |> change_form(act: Acts.Controls.Act.Attrs.invalid())
      |> assert_form_error(:act, :title, "can't be blank")

      create_attrs = Acts.Controls.Act.Attrs.valid()

      image =
        file_input(index_live, "#act-form", :image, [
          Contents.Controls.Image.example()
        ])

      assert render_upload(image, "image_1.png") =~ "100%"

      {:ok, _, html} =
        index_live
        |> submit_form(act: create_attrs)
        |> follow_redirect(conn, Routes.act_index_path(conn, :index))

      html
      |> assert_flash(:info, "Act created successfully")
      |> assert_resource(:act, :title, act_id, create_attrs.title)
    end

    test "updates act in listing", %{conn: conn, act: act} do
      {:ok, index_live, _html} = list_acts(conn)

      index_live
      |> edit_act(act)
      |> assert_html("h2", "Edit Act")

      assert_patch(index_live, Routes.act_index_path(conn, :edit, act))

      index_live
      |> form(@form_identifier, act: Acts.Controls.Act.Attrs.invalid())
      |> render_change()
      |> assert_form_error(:act, :title, "can't be blank")

      update_attrs = Acts.Controls.Act.Attrs.valid(title: "Changed Title")

      {:ok, _, html} =
        index_live
        |> form(@form_identifier, act: update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.act_index_path(conn, :index))

      html
      |> assert_flash(:info, "Act updated successfully")
      |> assert_resource(:act, :title, act.id, update_attrs.title)
    end

    test "deletes act in listing", %{conn: conn, act: act} do
      {:ok, index_live, _html} = list_acts(conn)

      index_live
      |> delete_act(act)
      |> refute_resource(:act, act)
    end

    defp list_acts(conn, params \\ %{}) do
      live(conn, Routes.act_index_path(conn, :index, params))
    end

    defp new_act(live) do
      live
      |> element("[data-resource-type=act] [data-action=new]")
      |> render_click()
    end

    defp edit_act(live, act) do
      live
      |> element("[data-resource-id=#{act.id}] [data-action=edit]")
      |> render_click()
    end

    defp delete_act(live, act) do
      live
      |> element("[data-resource-id=#{act.id}] [data-action=delete]")
      |> render_click()
    end

    defp new_show(live) do
      live
      |> element("[data-resource-type=show] [data-action=new]")
      |> render_click()
    end
  end

  describe "Show" do
    setup [:create_act]

    test "displays act", %{conn: conn, act: act} do
      {:ok, _show_live, html} = show_act(conn, act)

      html
      |> assert_html("h1", "Show Act")
      |> assert_resource(:act, :title, act)
    end

    test "updates act within modal", %{conn: conn, act: act} do
      {:ok, show_live, _html} = show_act(conn, act)

      show_live
      |> edit_act()
      |> assert_html("[data-resource-type=act] h2", "Edit Act")

      assert_patch(show_live, Routes.act_show_path(conn, :edit, act))

      show_live
      |> form(@form_identifier, act: Acts.Controls.Act.Attrs.invalid())
      |> render_change()
      |> assert_form_error(:act, :title, "can't be blank")

      update_attrs = Acts.Controls.Act.Attrs.valid(title: "Changed Title")
      {:ok, _, html} = update_act(conn, show_live, act, update_attrs)

      html
      |> assert_flash(:info, "Act updated successfully")
      |> assert_resource(:act, :title, act.id, "Changed Title")
    end

    defp edit_act(live) do
      live
      |> element("[data-resource-type=act] [data-action=edit]")
      |> render_click()
    end

    defp show_act(conn, act) do
      live(conn, Routes.act_show_path(conn, :show, act))
    end

    defp update_act(conn, live, act, attrs) do
      live
      |> form(@form_identifier, act: attrs)
      |> render_submit()
      |> follow_redirect(conn, Routes.act_show_path(conn, :show, act))
    end
  end

  describe "Shows" do
    setup [:create_act, :create_venue, :schedule_show]

    test "lists show", %{conn: conn, act: act, show: show} do
      {:ok, _show_live, html} = show_act(conn, act)

      html
      |> assert_html("[data-resource-type=show] h2", "Listing Shows")
      |> assert_resource(:show, :start_at, show.venue.id, Clock.Controls.DateTime.string())
    end

    test "schedules a new show", %{conn: conn, act: act} do
      venue = Venues.Controls.Venue.example(id: Identifier.Uuid.Controls.Random.example())
      {:ok, _venue} = Venues.Handlers.Commands.save_venue(venue)

      {:ok, show_live, _html} = show_act(conn, act)

      show_live
      |> new_show()
      |> assert_html("[data-resource-type=show] h3", "New Show")

      assert_patch(show_live, Routes.act_show_path(conn, :new_show, act))

      create_attrs = Shows.Controls.Show.Attrs.valid(venue_id: venue.id)

      {:ok, _, html} =
        show_live
        |> submit_show_form(show: create_attrs)
        |> follow_redirect(conn, Routes.act_show_path(conn, :show, act))

      date_time_as_string = Clock.Controls.DateTime.to_string(~U[2027-01-01 00:00:00.000000Z])

      html
      |> assert_flash(:info, "Show created successfully")
      |> assert_resource(:show, :start_at, venue.id, to_string(date_time_as_string))
    end

    test "cancels a scheduled show", %{conn: conn, act: act, venue: venue} do
      {:ok, show_live, _html} = show_act(conn, act)

      show_live
      |> delete_show(venue)
      |> refute_resource(:venue, venue)
    end

    defp delete_show(live, venue) do
      live
      |> element("[data-resource-id=#{venue.id}] [data-action=delete]")
      |> render_click()
    end
  end

  defp change_form(live, attrs) do
    live
    |> form(@form_identifier, attrs)
    |> render_change()
  end

  defp submit_form(live, attrs) do
    live
    |> form(@form_identifier, attrs)
    |> render_submit()
  end

  defp submit_show_form(live, attrs) do
    live
    |> form("#show-form", attrs)
    |> render_submit()
  end
end
