defmodule UniverseWeb.TepicHouseCalculatorLiveTest do
  use UniverseWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "renders calculator route and comparison cards", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/tools/tepic-house-calculator")

    assert has_element?(view, "#tepic-house-calculator-page")
    assert has_element?(view, "#tepic-house-calculator-form")
    assert has_element?(view, "#tepic-cost-source-table.calculator-table")
    assert has_element?(view, "input.calculator-input")
    assert has_element?(view, "#canada-comparison-card", "Canada single property")
    assert has_element?(view, "#tepic-portfolio-comparison-card")
    assert has_element?(view, "#houses-possible", "20")
    assert html =~ ~r/name="calculator\[exchange_rate_mxn_per_cad\]".*value="12\.5"/s
    assert html =~ ~s(name="calculator[tepic_rent_low_mxn]")
  end

  test "recalculates geometry and capital comparison on input change", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/tools/tepic-house-calculator")

    view
    |> form("#tepic-house-calculator-form", %{
      calculator: %{
        length_m: "12",
        width_m: "9",
        exchange_rate_mxn_per_cad: "10",
        bathroom_count: "2"
      }
    })
    |> render_change()

    assert has_element?(view, "#footprint-area", "108.00")
    assert has_element?(view, "#houses-possible", "11")
    assert has_element?(view, "#monthly-rent-cad", "CAD 250.00 - CAD 300.00")
  end
end
