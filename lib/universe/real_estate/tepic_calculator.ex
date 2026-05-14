defmodule Universe.RealEstate.TepicCalculator do
  @moduledoc """
  Plain, testable calculations for the Tepic House Calculator.

  The first version stays DB-free and loads editable default presets from
  `priv/data/tepic_cost_presets.json`.
  """

  @external_resource Path.expand("../../../priv/data/tepic_cost_presets.json", __DIR__)
  @preset_data @external_resource |> File.read!() |> Jason.decode!()

  @default_inputs Enum.into(@preset_data["default_inputs"], %{}, fn {key, value} ->
                    {String.to_atom(key), value}
                  end)
  @cost_source_rows @preset_data["cost_source_rows"]

  @integer_fields ~w(
    floors
    bathroom_count
    kitchen_count
    main_door_count
    interior_door_count
    window_count
  )a

  @doc "Returns the normalized default calculator inputs."
  def defaults, do: @default_inputs

  @doc "Returns the field types used to build typed calculator forms."
  def field_types do
    Enum.into(@default_inputs, %{}, fn {key, _value} ->
      type = if key in @integer_fields, do: :integer, else: :float
      {key, type}
    end)
  end

  @doc "Returns default inputs as string values suitable for a Phoenix form."
  def default_form_inputs do
    @default_inputs
    |> stringify_inputs()
  end

  @doc "Returns placeholder pricing rows for the first DB-free version."
  def cost_source_rows, do: @cost_source_rows

  @doc """
  Calculates geometry, cost, and ROI outputs from the given input map.

  The input map may use either atom or string keys.
  """
  def calculate(params \\ %{}) when is_map(params) do
    inputs = normalize_inputs(params)
    measurements = measurements(inputs)
    costs = costs(inputs, measurements)
    comparison = comparison(inputs, costs)

    %{
      inputs: inputs,
      form_inputs: stringify_inputs(inputs),
      measurements: measurements,
      costs: costs,
      comparison: comparison,
      sources: @cost_source_rows
    }
  end

  defp normalize_inputs(params) do
    Enum.reduce(@default_inputs, %{}, fn {key, default}, acc ->
      raw_value = Map.get(params, key, Map.get(params, Atom.to_string(key), default))
      Map.put(acc, key, normalize_value(key, raw_value, default))
    end)
  end

  defp normalize_value(key, value, default) when key in @integer_fields do
    case parse_number(value) do
      {:ok, parsed} -> max(parsed |> round(), 0)
      :error -> default
    end
  end

  defp normalize_value(key, value, default) do
    case parse_number(value) do
      {:ok, parsed} ->
        parsed
        |> max(minimum_for(key))
        |> round_to(4)

      :error ->
        default
    end
  end

  defp parse_number(value) when is_integer(value), do: {:ok, value * 1.0}
  defp parse_number(value) when is_float(value), do: {:ok, value}

  defp parse_number(value) when is_binary(value) do
    trimmed = String.trim(value)

    cond do
      trimmed == "" ->
        :error

      match?({_, ""}, Integer.parse(trimmed)) ->
        {parsed, ""} = Integer.parse(trimmed)
        {:ok, parsed * 1.0}

      match?({_, ""}, Float.parse(trimmed)) ->
        {parsed, ""} = Float.parse(trimmed)
        {:ok, parsed}

      true ->
        :error
    end
  end

  defp parse_number(_value), do: :error

  defp minimum_for(:exchange_rate_mxn_per_cad), do: 0.01
  defp minimum_for(:roof_factor), do: 1.0
  defp minimum_for(:stud_spacing_m), do: 0.1
  defp minimum_for(:drywall_board_area_m2), do: 0.1
  defp minimum_for(:track_piece_length_m), do: 0.1
  defp minimum_for(_key), do: 0.0

  defp measurements(inputs) do
    footprint_area_m2 = inputs.length_m * inputs.width_m
    floor_area_m2 = footprint_area_m2 * inputs.floors
    perimeter_m = 2 * (inputs.length_m + inputs.width_m)
    exterior_wall_area_m2 = max(perimeter_m * inputs.wall_height_m - inputs.opening_area_m2, 0.0)
    roof_area_m2 = footprint_area_m2 * inputs.roof_factor
    footing_linear_m = perimeter_m + inputs.load_bearing_interior_footing_length_m
    footing_volume_m3 = footing_linear_m * inputs.footing_width_m * inputs.footing_depth_m
    slab_volume_m3 = floor_area_m2 * inputs.slab_thickness_m
    total_concrete_volume_m3 = footing_volume_m3 + slab_volume_m3
    interior_wall_area_one_side_m2 = inputs.interior_wall_linear_m * inputs.interior_wall_height_m
    interior_wall_area_both_sides_m2 = interior_wall_area_one_side_m2 * 2
    stud_count_approx = ceil_count(inputs.interior_wall_linear_m / inputs.stud_spacing_m) + 1

    drywall_board_count =
      ceil_count(interior_wall_area_both_sides_m2 / inputs.drywall_board_area_m2)

    track_piece_count =
      ceil_count(inputs.interior_wall_linear_m * 2 / inputs.track_piece_length_m)

    cabinet_linear_total_m = inputs.kitchen_count * inputs.cabinet_linear_m_per_kitchen

    %{
      footprint_area_m2: round_to(footprint_area_m2),
      floor_area_m2: round_to(floor_area_m2),
      perimeter_m: round_to(perimeter_m),
      exterior_wall_area_m2: round_to(exterior_wall_area_m2),
      roof_area_m2: round_to(roof_area_m2),
      footing_linear_m: round_to(footing_linear_m),
      footing_volume_m3: round_to(footing_volume_m3),
      slab_volume_m3: round_to(slab_volume_m3),
      total_concrete_volume_m3: round_to(total_concrete_volume_m3),
      interior_wall_area_one_side_m2: round_to(interior_wall_area_one_side_m2),
      interior_wall_area_both_sides_m2: round_to(interior_wall_area_both_sides_m2),
      stud_count_approx: stud_count_approx,
      drywall_board_count: drywall_board_count,
      track_piece_count: track_piece_count,
      cabinet_linear_total_m: round_to(cabinet_linear_total_m)
    }
  end

  defp costs(inputs, measurements) do
    concrete_cost_mxn = measurements.total_concrete_volume_m3 * inputs.concrete_cost_m3_mxn
    rebar_weight_kg = measurements.total_concrete_volume_m3 * inputs.rebar_kg_per_m3
    rebar_cost_mxn = rebar_weight_kg * inputs.rebar_cost_kg_mxn

    foundation_mxn =
      concrete_cost_mxn +
        rebar_cost_mxn +
        inputs.formwork_allowance_mxn +
        measurements.floor_area_m2 * inputs.gravel_base_cost_m2_mxn +
        inputs.foundation_labor_allowance_mxn

    exterior_walls_mxn =
      measurements.exterior_wall_area_m2 *
        (inputs.exterior_wall_unit_cost_m2_mxn + inputs.exterior_wall_labor_cost_m2_mxn)

    roof_mxn =
      measurements.roof_area_m2 *
        (inputs.roof_material_cost_m2_mxn + inputs.roof_waterproofing_cost_m2_mxn +
           inputs.roof_labor_cost_m2_mxn)

    interior_walls_mxn =
      measurements.drywall_board_count * inputs.drywall_board_cost_mxn +
        measurements.stud_count_approx * inputs.metal_stud_cost_mxn +
        measurements.track_piece_count * inputs.track_cost_mxn +
        inputs.screws_tape_mud_allowance_mxn +
        measurements.interior_wall_area_both_sides_m2 *
          (inputs.interior_paint_cost_m2_mxn + inputs.interior_wall_labor_cost_m2_mxn)

    bathrooms_mxn =
      inputs.bathroom_count *
        (inputs.toilet_cost_mxn +
           inputs.sink_vanity_cost_mxn +
           inputs.shower_cost_mxn +
           inputs.bathroom_faucet_cost_mxn +
           inputs.bathroom_tile_allowance_mxn +
           inputs.bathroom_plumbing_allowance_mxn +
           inputs.bathroom_labor_allowance_mxn)

    kitchen_mxn =
      inputs.kitchen_count *
        (inputs.cabinet_linear_m_per_kitchen *
           (inputs.cabinet_cost_linear_m_mxn + inputs.countertop_cost_linear_m_mxn) +
           inputs.kitchen_sink_cost_mxn +
           inputs.kitchen_faucet_cost_mxn +
           inputs.basic_appliance_allowance_mxn)

    services_mxn =
      measurements.floor_area_m2 * inputs.electrical_rough_in_cost_m2_mxn +
        inputs.plumbing_rough_in_allowance_mxn +
        inputs.main_door_count * inputs.main_door_cost_mxn +
        inputs.interior_door_count * inputs.interior_door_cost_mxn +
        inputs.window_count * inputs.window_cost_mxn

    other_mxn =
      inputs.permits_design_allowance_mxn +
        inputs.site_preparation_mxn +
        inputs.paint_allowance_mxn +
        measurements.floor_area_m2 * inputs.flooring_cost_m2_mxn

    base_total_mxn =
      foundation_mxn + exterior_walls_mxn + roof_mxn + interior_walls_mxn + bathrooms_mxn +
        kitchen_mxn + services_mxn + other_mxn

    contingency_mxn = base_total_mxn * inputs.contingency_percent / 100

    contractor_management_mxn =
      (base_total_mxn + contingency_mxn) * inputs.contractor_management_percent / 100

    total_build_cost_mxn = base_total_mxn + contingency_mxn + contractor_management_mxn
    total_build_cost_cad = total_build_cost_mxn / inputs.exchange_rate_mxn_per_cad
    cost_per_m2_mxn = total_build_cost_mxn / max(measurements.floor_area_m2, 0.01)
    cost_per_m2_cad = total_build_cost_cad / max(measurements.floor_area_m2, 0.01)

    %{
      foundation_mxn: round_to(foundation_mxn),
      exterior_walls_mxn: round_to(exterior_walls_mxn),
      roof_mxn: round_to(roof_mxn),
      interior_walls_mxn: round_to(interior_walls_mxn),
      bathrooms_mxn: round_to(bathrooms_mxn),
      kitchen_mxn: round_to(kitchen_mxn),
      services_mxn: round_to(services_mxn),
      other_mxn: round_to(other_mxn),
      base_total_mxn: round_to(base_total_mxn),
      contingency_mxn: round_to(contingency_mxn),
      contractor_management_mxn: round_to(contractor_management_mxn),
      total_build_cost_mxn: round_to(total_build_cost_mxn),
      total_build_cost_cad: round_to(total_build_cost_cad),
      cost_per_m2_mxn: round_to(cost_per_m2_mxn),
      cost_per_m2_cad: round_to(cost_per_m2_cad),
      rebar_weight_kg: round_to(rebar_weight_kg),
      concrete_cost_mxn: round_to(concrete_cost_mxn),
      rebar_cost_mxn: round_to(rebar_cost_mxn)
    }
  end

  defp comparison(inputs, costs) do
    tepic_monthly_rent_low_cad = inputs.tepic_rent_low_mxn / inputs.exchange_rate_mxn_per_cad
    tepic_monthly_rent_high_cad = inputs.tepic_rent_high_mxn / inputs.exchange_rate_mxn_per_cad
    tepic_annual_rent_low_cad = tepic_monthly_rent_low_cad * 12
    tepic_annual_rent_high_cad = tepic_monthly_rent_high_cad * 12

    tepic_monthly_roi_low_percent = tepic_monthly_rent_low_cad / costs.total_build_cost_cad * 100

    tepic_monthly_roi_high_percent =
      tepic_monthly_rent_high_cad / costs.total_build_cost_cad * 100

    tepic_annual_roi_low_percent = tepic_annual_rent_low_cad / costs.total_build_cost_cad * 100
    tepic_annual_roi_high_percent = tepic_annual_rent_high_cad / costs.total_build_cost_cad * 100

    canada_monthly_roi_low_percent =
      inputs.canadian_rent_low_cad / inputs.canadian_property_cost_cad * 100

    canada_monthly_roi_high_percent =
      inputs.canadian_rent_high_cad / inputs.canadian_property_cost_cad * 100

    canada_annual_roi_low_percent =
      inputs.canadian_rent_low_cad * 12 / inputs.canadian_property_cost_cad * 100

    canada_annual_roi_high_percent =
      inputs.canadian_rent_high_cad * 12 / inputs.canadian_property_cost_cad * 100

    houses_per_canadian_property =
      floor(inputs.canadian_property_cost_cad / max(costs.total_build_cost_cad, 0.01))

    target_houses_per_canadian_property =
      floor(inputs.canadian_property_cost_cad / max(inputs.target_build_cost_cad, 0.01))

    tepic_portfolio_rent_low_mxn = houses_per_canadian_property * inputs.tepic_rent_low_mxn
    tepic_portfolio_rent_high_mxn = houses_per_canadian_property * inputs.tepic_rent_high_mxn
    tepic_portfolio_rent_low_cad = houses_per_canadian_property * tepic_monthly_rent_low_cad
    tepic_portfolio_rent_high_cad = houses_per_canadian_property * tepic_monthly_rent_high_cad

    build_cost_gap_cad = costs.total_build_cost_cad - inputs.target_build_cost_cad

    %{
      tepic_monthly_rent_low_cad: round_to(tepic_monthly_rent_low_cad),
      tepic_monthly_rent_high_cad: round_to(tepic_monthly_rent_high_cad),
      tepic_annual_rent_low_cad: round_to(tepic_annual_rent_low_cad),
      tepic_annual_rent_high_cad: round_to(tepic_annual_rent_high_cad),
      tepic_monthly_roi_low_percent: round_to(tepic_monthly_roi_low_percent),
      tepic_monthly_roi_high_percent: round_to(tepic_monthly_roi_high_percent),
      tepic_annual_roi_low_percent: round_to(tepic_annual_roi_low_percent),
      tepic_annual_roi_high_percent: round_to(tepic_annual_roi_high_percent),
      canada_monthly_roi_low_percent: round_to(canada_monthly_roi_low_percent),
      canada_monthly_roi_high_percent: round_to(canada_monthly_roi_high_percent),
      canada_annual_roi_low_percent: round_to(canada_annual_roi_low_percent),
      canada_annual_roi_high_percent: round_to(canada_annual_roi_high_percent),
      houses_per_canadian_property: houses_per_canadian_property,
      target_houses_per_canadian_property: target_houses_per_canadian_property,
      tepic_portfolio_rent_low_mxn: round_to(tepic_portfolio_rent_low_mxn),
      tepic_portfolio_rent_high_mxn: round_to(tepic_portfolio_rent_high_mxn),
      tepic_portfolio_rent_low_cad: round_to(tepic_portfolio_rent_low_cad),
      tepic_portfolio_rent_high_cad: round_to(tepic_portfolio_rent_high_cad),
      build_cost_gap_cad: round_to(build_cost_gap_cad)
    }
  end

  defp stringify_inputs(inputs) do
    Enum.into(inputs, %{}, fn {key, value} ->
      {Atom.to_string(key), format_input(value)}
    end)
  end

  defp format_input(value) when is_integer(value), do: Integer.to_string(value)

  defp format_input(value) when is_float(value) do
    rounded = round_to(value, 4)

    if rounded == trunc(rounded) do
      rounded |> trunc() |> Integer.to_string()
    else
      :erlang.float_to_binary(rounded, decimals: 4)
      |> String.trim_trailing("0")
      |> String.trim_trailing(".")
    end
  end

  defp ceil_count(value) when value <= 0, do: 0
  defp ceil_count(value), do: value |> Float.ceil() |> trunc()

  defp round_to(number, precision \\ 2) do
    factor = :math.pow(10, precision)

    Float.round(number * 1.0, precision)
    |> Kernel.+(0.0)
    |> then(fn rounded -> Float.round(rounded * factor) / factor end)
  end
end
