defmodule Universe.RealEstate.LowCostHousingCalculatorTest do
  use ExUnit.Case, async: true

  alias Universe.RealEstate.LowCostHousingCalculator

  test "uses the spreadsheet title from cell A1 and computes default totals" do
    result = LowCostHousingCalculator.calculate()

    assert result.title == "Low cost housing construction in Mexico"
    assert result.summary.footprint_area_m2 == 56.0
    assert result.summary.land_cost_mxn == 105_000.0
    assert result.summary.base_construction_cost_mxn == 520_180.0
    assert result.summary.contingency_mxn == 52_018.0
    assert result.summary.total_cost_mxn == 677_198.0
    assert result.summary.total_cost_cad == 47_403.86
  end

  test "editable assumptions update land, total cost, and profit" do
    result =
      LowCostHousingCalculator.calculate(%{
        "land_price_mxn_per_m2" => "1200",
        "sale_price_mxn" => "1500000"
      })

    assert result.summary.land_cost_mxn == 126_000.0
    assert result.summary.total_cost_mxn == 698_198.0
    assert result.summary.profit_mxn == 801_802.0
  end
end
