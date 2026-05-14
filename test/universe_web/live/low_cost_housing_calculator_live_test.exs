defmodule UniverseWeb.LowCostHousingCalculatorLiveTest do
  use UniverseWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "renders the spreadsheet page with the A1 title and prefilled assumptions", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/tools/low-cost-housing-construction-in-mexico")

    assert has_element?(view, "#low-cost-housing-page")
    assert has_element?(view, "#low-cost-housing-form")
    assert has_element?(view, "#low-cost-line-items-table.calculator-table")
    assert has_element?(view, "input.calculator-input")
    assert html =~ "Low cost housing construction in Mexico"
    assert html =~ ~r/name="calculator\[width_m\]".*value="7(?:\.0+)?"/s
    assert html =~ ~r/name="calculator\[length_m\]".*value="8(?:\.0+)?"/s
    assert html =~ ~s(name="calculator[land_price_mxn_per_m2]")
  end

  test "recalculates totals when assumptions change", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/tools/low-cost-housing-construction-in-mexico")

    view
    |> form("#low-cost-housing-form", %{
      calculator: %{
        land_price_mxn_per_m2: "1200",
        sale_price_mxn: "1500000"
      }
    })
    |> render_change()

    assert has_element?(view, "#low-cost-total-cost", "MXN 698,198.00")
    assert has_element?(view, "#low-cost-profit-mxn", "MXN 801,802.00")
  end
end
