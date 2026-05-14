defmodule Universe.RealEstate.TepicCalculatorTest do
  use ExUnit.Case, async: true

  alias Universe.RealEstate.TepicCalculator

  test "default calculation derives geometry and same-capital comparison" do
    result = TepicCalculator.calculate()

    assert result.measurements.footprint_area_m2 == 63.0
    assert result.measurements.perimeter_m == 32.0
    assert result.measurements.roof_area_m2 == 69.3
    assert result.measurements.exterior_wall_area_m2 == 79.6
    assert result.measurements.footing_volume_m3 == 10.8
    assert result.measurements.slab_volume_m3 == 7.56

    assert_in_delta result.costs.total_build_cost_cad, 50_000, 1_000
    assert result.comparison.houses_per_canadian_property == 20
    assert result.comparison.target_houses_per_canadian_property == 20
    assert result.comparison.tepic_monthly_rent_low_cad == 200.0
    assert result.comparison.tepic_monthly_rent_high_cad == 240.0
  end

  test "editable rent and exchange assumptions change ROI and portfolio rent" do
    result =
      TepicCalculator.calculate(%{
        "exchange_rate_mxn_per_cad" => "10",
        "tepic_rent_low_mxn" => "3000",
        "tepic_rent_high_mxn" => "3500"
      })

    assert result.comparison.tepic_monthly_rent_low_cad == 300.0
    assert result.comparison.tepic_monthly_rent_high_cad == 350.0

    assert result.comparison.tepic_monthly_roi_high_percent >
             result.comparison.tepic_monthly_roi_low_percent

    assert result.comparison.tepic_portfolio_rent_high_cad >
             result.comparison.tepic_portfolio_rent_low_cad
  end

  test "interior wall inputs drive drywall quantities and counts" do
    result =
      TepicCalculator.calculate(%{
        "interior_wall_linear_m" => "30",
        "interior_wall_height_m" => "3",
        "stud_spacing_m" => "0.5",
        "drywall_board_area_m2" => "3"
      })

    assert result.measurements.interior_wall_area_one_side_m2 == 90.0
    assert result.measurements.interior_wall_area_both_sides_m2 == 180.0
    assert result.measurements.stud_count_approx == 61
    assert result.measurements.drywall_board_count == 60
  end
end
