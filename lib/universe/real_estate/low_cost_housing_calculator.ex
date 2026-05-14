defmodule Universe.RealEstate.LowCostHousingCalculator do
  @moduledoc """
  Snapshot-backed calculator for the "Low cost housing construction in Mexico"
  spreadsheet page.

  The page keeps the original spreadsheet assumptions editable while presenting
  the model as a Phoenix LiveView instead of a raw grid.
  """

  @title "Low cost housing construction in Mexico"
  @description """
  Two one floor single dwellings share a foundation and roof to save cost. Each \
  home is two bedroom, one bathroom, kitchen and living room. Lot size is 7 \
  meters by 15 meters. Banorte is looking for 750,000 peso homes to finance \
  for customers.
  """

  @source_url "https://docs.google.com/spreadsheets/d/1WN3wmIiURpRbV8DTdstDEJynil3yWAsF3dMB81XE2-M/edit?usp=sharing"

  @defaults %{
    width_m: 7.0,
    length_m: 8.0,
    land_area_m2: 105.0,
    land_price_mxn_per_m2: 1000.0,
    unit_count: 2,
    foundation_cost_mxn: 15_150.0,
    lock_up_cost_mxn: 209_840.0,
    finishing_cost_mxn: 295_190.0,
    contingency_percent: 10.0,
    sale_price_mxn: 1_380_000.0,
    cad_per_1000_mxn: 70.0,
    usd_per_1000_mxn: 50.0,
    build_months: 8.0
  }

  @integer_fields ~w(unit_count)a

  @line_items [
    %{
      phase: "Purchase Land",
      item: "Land",
      unit: "m²",
      quantity: 105.0,
      unit_cost_mxn: 1000.0,
      total_mxn: 105_000.0
    },
    %{
      phase: "Foundation Stage",
      item: "Labor",
      unit: "m",
      quantity: 56.0,
      unit_cost_mxn: 200.0,
      total_mxn: 11_200.0
    },
    %{
      phase: "Foundation Stage",
      item: "Mesh",
      unit: "4 x 20M",
      quantity: 0.5,
      unit_cost_mxn: 3500.0,
      total_mxn: 1750.0
    },
    %{
      phase: "Foundation Stage",
      item: "Concrete",
      unit: "bag",
      quantity: 10.0,
      unit_cost_mxn: 220.0,
      total_mxn: 2200.0
    },
    %{
      phase: "Lock Up Stage",
      item: "Walls",
      unit: "m²",
      quantity: 75.0,
      unit_cost_mxn: 100.0,
      total_mxn: 7500.0
    },
    %{
      phase: "Lock Up Stage",
      item: "Rebar labor",
      unit: "m",
      quantity: 46.0,
      unit_cost_mxn: 120.0,
      total_mxn: 5520.0
    },
    %{
      phase: "Lock Up Stage",
      item: "Bricks",
      unit: "m²",
      quantity: 75.0,
      unit_cost_mxn: 330.0,
      total_mxn: 24_750.0
    },
    %{
      phase: "Lock Up Stage",
      item: "Sand",
      unit: "m³",
      quantity: 5.0,
      unit_cost_mxn: 3000.0,
      total_mxn: 15_000.0
    },
    %{
      phase: "Lock Up Stage",
      item: "Beams",
      unit: "m",
      quantity: 30.0,
      unit_cost_mxn: 525.0,
      total_mxn: 15_750.0
    },
    %{
      phase: "Lock Up Stage",
      item: "Labor",
      unit: "m²",
      quantity: 56.0,
      unit_cost_mxn: 150.0,
      total_mxn: 8400.0
    },
    %{
      phase: "Interior / Finishing",
      item: "Exterior wall plaster",
      unit: "m²",
      quantity: 112.5,
      unit_cost_mxn: 120.0,
      total_mxn: 13_500.0
    },
    %{
      phase: "Interior / Finishing",
      item: "Interior wall plaster",
      unit: "m²",
      quantity: 32.0,
      unit_cost_mxn: 120.0,
      total_mxn: 3840.0
    },
    %{
      phase: "Interior / Finishing",
      item: "Tile",
      unit: "m²",
      quantity: 56.0,
      unit_cost_mxn: 190.0,
      total_mxn: 10_640.0
    },
    %{
      phase: "Interior / Finishing",
      item: "Electrical labor",
      unit: "allowance",
      quantity: 1.0,
      unit_cost_mxn: 3000.0,
      total_mxn: 3000.0
    },
    %{
      phase: "Interior / Finishing",
      item: "Hot water heater",
      unit: "each",
      quantity: 1.0,
      unit_cost_mxn: 4000.0,
      total_mxn: 4000.0
    },
    %{
      phase: "Interior / Finishing",
      item: "Sink and toilet",
      unit: "bathroom set",
      quantity: 1.0,
      unit_cost_mxn: 2200.0,
      total_mxn: 2200.0
    },
    %{
      phase: "Interior / Finishing",
      item: "Kitchen sink with faucet",
      unit: "each",
      quantity: 1.0,
      unit_cost_mxn: 3700.0,
      total_mxn: 3700.0
    },
    %{
      phase: "Interior / Finishing",
      item: "Paint labor",
      unit: "allowance",
      quantity: 4.0,
      unit_cost_mxn: 3500.0,
      total_mxn: 14_000.0
    },
    %{
      phase: "Interior / Finishing",
      item: "Outdoor doors",
      unit: "each",
      quantity: 2.0,
      unit_cost_mxn: 2000.0,
      total_mxn: 4000.0
    },
    %{
      phase: "Interior / Finishing",
      item: "Windows",
      unit: "each",
      quantity: 4.0,
      unit_cost_mxn: 4000.0,
      total_mxn: 16_000.0
    }
  ]

  @forecast_rows [
    %{
      period: 1,
      years: 0.67,
      homes: 2,
      cumulative_cost: 94_000.0,
      sale_value: 98_000.0,
      monthly_profit: 3280.0
    },
    %{
      period: 2,
      years: 1.33,
      homes: 4,
      cumulative_cost: 188_000.0,
      sale_value: 196_000.0,
      monthly_profit: 9840.0
    },
    %{
      period: 3,
      years: 2.0,
      homes: 8,
      cumulative_cost: 376_000.0,
      sale_value: 392_000.0,
      monthly_profit: 22_960.0
    },
    %{
      period: 4,
      years: 2.67,
      homes: 16,
      cumulative_cost: 752_000.0,
      sale_value: 784_000.0,
      monthly_profit: 49_200.0
    },
    %{
      period: 5,
      years: 3.33,
      homes: 32,
      cumulative_cost: 752_000.0,
      sale_value: 1_568_000.0,
      monthly_profit: 718_320.0
    },
    %{
      period: 6,
      years: 4.0,
      homes: 32,
      cumulative_cost: 752_000.0,
      sale_value: 1_568_000.0,
      monthly_profit: 1_387_440.0
    },
    %{
      period: 7,
      years: 4.67,
      homes: 32,
      cumulative_cost: 752_000.0,
      sale_value: 1_568_000.0,
      monthly_profit: 2_056_560.0
    },
    %{
      period: 8,
      years: 5.33,
      homes: 32,
      cumulative_cost: 752_000.0,
      sale_value: 1_568_000.0,
      monthly_profit: 2_725_680.0
    },
    %{
      period: 9,
      years: 6.0,
      homes: 32,
      cumulative_cost: 752_000.0,
      sale_value: 1_568_000.0,
      monthly_profit: 3_394_800.0
    },
    %{
      period: 10,
      years: 6.67,
      homes: 32,
      cumulative_cost: 752_000.0,
      sale_value: 1_568_000.0,
      monthly_profit: 4_063_920.0
    },
    %{
      period: 11,
      years: 7.33,
      homes: 32,
      cumulative_cost: 752_000.0,
      sale_value: 1_568_000.0,
      monthly_profit: 4_733_040.0
    },
    %{
      period: 12,
      years: 8.0,
      homes: 32,
      cumulative_cost: 752_000.0,
      sale_value: 1_568_000.0,
      monthly_profit: 5_402_160.0
    }
  ]

  def title, do: @title
  def description, do: @description
  def source_url, do: @source_url
  def line_items, do: @line_items
  def forecast_rows, do: @forecast_rows

  def field_types do
    Enum.into(@defaults, %{}, fn {key, _value} ->
      type = if key in @integer_fields, do: :integer, else: :float
      {key, type}
    end)
  end

  def default_form_inputs do
    @defaults
    |> stringify_inputs()
  end

  def calculate(params \\ %{}) when is_map(params) do
    inputs = normalize_inputs(params)

    land_cost_mxn = round_to(inputs.land_area_m2 * inputs.land_price_mxn_per_m2)
    footprint_area_m2 = round_to(inputs.width_m * inputs.length_m)
    per_unit_area_m2 = round_to(footprint_area_m2 / max(inputs.unit_count, 1))

    base_construction_cost_mxn =
      round_to(inputs.foundation_cost_mxn + inputs.lock_up_cost_mxn + inputs.finishing_cost_mxn)

    contingency_mxn = round_to(base_construction_cost_mxn * inputs.contingency_percent / 100)
    total_cost_mxn = round_to(land_cost_mxn + base_construction_cost_mxn + contingency_mxn)
    construction_only_total_mxn = round_to(base_construction_cost_mxn + contingency_mxn)
    total_cost_cad = round_to(total_cost_mxn / 1000 * inputs.cad_per_1000_mxn)
    total_cost_usd = round_to(total_cost_mxn / 1000 * inputs.usd_per_1000_mxn)
    sale_price_cad = round_to(inputs.sale_price_mxn / 1000 * inputs.cad_per_1000_mxn)
    sale_price_usd = round_to(inputs.sale_price_mxn / 1000 * inputs.usd_per_1000_mxn)
    profit_mxn = round_to(inputs.sale_price_mxn - total_cost_mxn)
    profit_cad = round_to(profit_mxn / 1000 * inputs.cad_per_1000_mxn)
    gross_margin_percent = round_to(safe_percent(profit_mxn, total_cost_mxn))
    cost_per_unit_mxn = round_to(total_cost_mxn / max(inputs.unit_count, 1))
    sale_per_unit_mxn = round_to(inputs.sale_price_mxn / max(inputs.unit_count, 1))
    project_monthly_profit_mxn = round_to(profit_mxn / max(inputs.build_months, 0.01))
    phase_rows = phase_rows(inputs, land_cost_mxn, contingency_mxn)

    %{
      title: @title,
      description: @description,
      source_url: @source_url,
      inputs: inputs,
      form_inputs: stringify_inputs(inputs),
      summary: %{
        land_cost_mxn: land_cost_mxn,
        footprint_area_m2: footprint_area_m2,
        per_unit_area_m2: per_unit_area_m2,
        base_construction_cost_mxn: base_construction_cost_mxn,
        construction_only_total_mxn: construction_only_total_mxn,
        contingency_mxn: contingency_mxn,
        total_cost_mxn: total_cost_mxn,
        total_cost_cad: total_cost_cad,
        total_cost_usd: total_cost_usd,
        sale_price_cad: sale_price_cad,
        sale_price_usd: sale_price_usd,
        profit_mxn: profit_mxn,
        profit_cad: profit_cad,
        gross_margin_percent: gross_margin_percent,
        cost_per_unit_mxn: cost_per_unit_mxn,
        sale_per_unit_mxn: sale_per_unit_mxn,
        project_monthly_profit_mxn: project_monthly_profit_mxn
      },
      phase_rows: phase_rows,
      line_items: @line_items,
      forecast_rows: @forecast_rows
    }
  end

  defp phase_rows(inputs, land_cost_mxn, contingency_mxn) do
    [
      %{
        phase: "Purchase Land",
        subtotal_mxn: land_cost_mxn,
        note: "Land area x land price assumption"
      },
      %{
        phase: "Foundation Stage",
        subtotal_mxn: inputs.foundation_cost_mxn,
        note: "From original sheet snapshot"
      },
      %{
        phase: "Lock Up Stage",
        subtotal_mxn: inputs.lock_up_cost_mxn,
        note: "Walls, roof, and shell work"
      },
      %{
        phase: "Interior / Finishing",
        subtotal_mxn: inputs.finishing_cost_mxn,
        note: "Finishes, electrical, plumbing, openings"
      },
      %{
        phase: "Construction Contingency",
        subtotal_mxn: contingency_mxn,
        note: "Editable percent on construction subtotal"
      }
    ]
  end

  defp normalize_inputs(params) do
    Enum.reduce(@defaults, %{}, fn {key, default}, acc ->
      raw_value = Map.get(params, key, Map.get(params, Atom.to_string(key), default))
      Map.put(acc, key, normalize_value(key, raw_value, default))
    end)
  end

  defp normalize_value(key, value, default) when key in @integer_fields do
    case parse_number(value) do
      {:ok, parsed} -> max(round(parsed), 1)
      :error -> default
    end
  end

  defp normalize_value(_key, value, default) do
    case parse_number(value) do
      {:ok, parsed} -> max(parsed, 0.0) |> round_to(4)
      :error -> default
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

  defp safe_percent(_numerator, denominator) when abs(denominator) < 1.0e-9, do: 0.0
  defp safe_percent(numerator, denominator), do: numerator / denominator * 100

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

  defp round_to(number, precision \\ 2) do
    Float.round(number * 1.0, precision)
  end
end
