defmodule UniverseWeb.CockpitLiveTest do
  use UniverseWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "labels dashboard panels with meaningful references", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/cockpit")

    assert has_element?(view, "#tactical-view-panel-label", "Tactical View")
    assert has_element?(view, "#weapons-control-panel-label", "Weapons Control")
    assert has_element?(view, "#phaser-bank-panel-label", "Phaser Bank")
    assert has_element?(view, "#photon-torpedoes-panel-label", "Photon Torpedoes")
    assert has_element?(view, "#navigation-systems-panel-label", "Navigation & Systems")
    assert has_element?(view, "#long-range-scanner-panel-label", "Long-Range Scanner")
    assert has_element?(view, "#ship-status-panel-label", "Ship Status")
    assert has_element?(view, "#mission-log-panel-label", "Mission Log")
  end

  test "keeps phaser beam overlay inside the tactical grid", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/cockpit")

    assert has_element?(view, "#tactical-grid > #laser-overlay")
    assert has_element?(view, "#tactical-grid .grid-cell[data-sector-x='5'][data-sector-y='5']")
  end

  test "shows Sol actions when landed at Sol", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/cockpit")

    view
    |> form("#warp-form", target_qx: 3, target_qy: 3)
    |> render_submit()

    assert has_element?(view, "#sol-actions-panel-label", "Sol")
    assert has_element?(view, "#sol-recharge-button", "Recharge")
    assert has_element?(view, "#sol-go-home-button", "Go Home")

    view
    |> element("#sol-go-home-button", "Go Home")
    |> render_click()

    assert_redirect(view, ~p"/tools")

    tools_html =
      conn
      |> get(~p"/tools")
      |> html_response(200)

    assert tools_html =~ "Tepic House Calculator"
    assert tools_html =~ "Low Cost Housing Construction in Mexico"
  end
end
