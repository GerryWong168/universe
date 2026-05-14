defmodule UniverseWeb.TepicHouseCalculatorLive do
  use UniverseWeb, :live_view

  alias Universe.RealEstate.TepicCalculator

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Tepic House Calculator")
     |> assign_result(TepicCalculator.calculate())}
  end

  @impl true
  def handle_event("recalculate", %{"calculator" => params}, socket) do
    {:noreply, assign_result(socket, TepicCalculator.calculate(params))}
  end

  @impl true
  def handle_event("reset", _params, socket) do
    {:noreply, assign_result(socket, TepicCalculator.calculate())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} variant={:tool}>
      <div
        id="tepic-house-calculator-page"
        class="min-h-screen rounded-[2rem] border border-sky-950/20 bg-[radial-gradient(circle_at_top_left,_rgba(14,165,233,0.2),_transparent_35%),linear-gradient(135deg,_#082f49,_#0f172a_40%,_#111827)] px-4 py-8 text-slate-100 shadow-2xl shadow-sky-950/30 sm:px-6 lg:px-8"
      >
        <div class="w-full space-y-8">
          <section class="grid gap-6 xl:grid-cols-[1.2fr_0.8fr] xl:items-end">
            <div class="space-y-4">
              <div class="inline-flex items-center gap-2 rounded-full border border-sky-300/20 bg-sky-300/10 px-3 py-1 text-xs font-semibold uppercase tracking-[0.28em] text-sky-100">
                <.icon name="hero-home-modern" class="size-4" /> Tepic House Calculator
              </div>
              <div class="space-y-3">
                <h1 class="max-w-3xl font-serif text-4xl font-semibold tracking-tight text-white sm:text-5xl">
                  Model Tepic build costs, rent yield, and the Canada-vs-Tepic cash-flow gap.
                </h1>
                <p class="max-w-3xl text-sm leading-7 text-slate-200 sm:text-base">
                  Edit dimensions, fixture counts, exchange rate, and rent assumptions to see how one
                  rental house in Tepic compares with a CAD $1,000,000 Canadian property.
                </p>
              </div>
            </div>

            <div class="grid gap-3 sm:grid-cols-3">
              <.hero_stat
                id="build-cost-cad"
                label="Current build cost"
                value={money(@result.costs.total_build_cost_cad, "CAD")}
                accent="from-amber-300/20 to-orange-400/20"
              />
              <.hero_stat
                id="houses-possible"
                label="Houses from CAD $1M"
                value={Integer.to_string(@result.comparison.houses_per_canadian_property)}
                accent="from-emerald-300/20 to-teal-400/20"
              />
              <.hero_stat
                id="annual-roi-high"
                label="Tepic annual ROI"
                value={
                  percent_range(
                    @result.comparison.tepic_annual_roi_low_percent,
                    @result.comparison.tepic_annual_roi_high_percent
                  )
                }
                accent="from-sky-300/20 to-cyan-400/20"
              />
            </div>
          </section>

          <div class="grid gap-8 xl:grid-cols-[1.15fr_0.85fr]">
            <.form
              for={@form}
              id="tepic-house-calculator-form"
              phx-change="recalculate"
              class="space-y-6"
            >
              <.section_card
                title="Assumptions"
                subtitle="Keep the model transparent: exchange, rents, and capital benchmark stay editable."
              >
                <div class="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
                  <.input
                    field={@form[:exchange_rate_mxn_per_cad]}
                    type="number"
                    step="0.01"
                    min="0.01"
                    label="Exchange rate (MXN per CAD)"
                  />
                  <.input
                    field={@form[:target_build_cost_cad]}
                    type="number"
                    step="1000"
                    min="0"
                    label="Target build cost (CAD)"
                  />
                  <.input
                    field={@form[:canadian_property_cost_cad]}
                    type="number"
                    step="1000"
                    min="0"
                    label="Canadian comparison property (CAD)"
                  />
                  <.input
                    field={@form[:canadian_rent_low_cad]}
                    type="number"
                    step="50"
                    min="0"
                    label="Canada rent low (CAD/month)"
                  />
                  <.input
                    field={@form[:canadian_rent_high_cad]}
                    type="number"
                    step="50"
                    min="0"
                    label="Canada rent high (CAD/month)"
                  />
                  <.input
                    field={@form[:tepic_rent_low_mxn]}
                    type="number"
                    step="50"
                    min="0"
                    label="Tepic rent low (MXN/month)"
                  />
                  <.input
                    field={@form[:tepic_rent_high_mxn]}
                    type="number"
                    step="50"
                    min="0"
                    label="Tepic rent high (MXN/month)"
                  />
                </div>
              </.section_card>

              <.section_card
                title="House Geometry"
                subtitle="Dimensions drive every downstream quantity, from footings to yield per dollar."
              >
                <div class="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
                  <.input
                    field={@form[:length_m]}
                    type="number"
                    step="0.1"
                    min="0"
                    label="Length (m)"
                  />
                  <.input field={@form[:width_m]} type="number" step="0.1" min="0" label="Width (m)" />
                  <.input
                    field={@form[:wall_height_m]}
                    type="number"
                    step="0.1"
                    min="0"
                    label="Wall height (m)"
                  />
                  <.input field={@form[:floors]} type="number" step="1" min="0" label="Floors" />
                  <.input
                    field={@form[:roof_factor]}
                    type="number"
                    step="0.01"
                    min="1"
                    label="Roof area factor"
                  />
                  <.input
                    field={@form[:slab_thickness_m]}
                    type="number"
                    step="0.01"
                    min="0"
                    label="Slab thickness (m)"
                  />
                  <.input
                    field={@form[:footing_width_m]}
                    type="number"
                    step="0.01"
                    min="0"
                    label="Footing width (m)"
                  />
                  <.input
                    field={@form[:footing_depth_m]}
                    type="number"
                    step="0.01"
                    min="0"
                    label="Footing depth (m)"
                  />
                  <.input
                    field={@form[:load_bearing_interior_footing_length_m]}
                    type="number"
                    step="0.1"
                    min="0"
                    label="Interior footing length (m)"
                  />
                  <.input
                    field={@form[:opening_area_m2]}
                    type="number"
                    step="0.1"
                    min="0"
                    label="Window and door deductions (m²)"
                  />
                </div>

                <div class="mt-4 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
                  <.mini_metric
                    id="footprint-area"
                    label="Footprint area"
                    value={unit(@result.measurements.footprint_area_m2, "m²")}
                  />
                  <.mini_metric
                    id="perimeter-value"
                    label="Perimeter"
                    value={unit(@result.measurements.perimeter_m, "m")}
                  />
                  <.mini_metric
                    id="roof-area"
                    label="Roof area"
                    value={unit(@result.measurements.roof_area_m2, "m²")}
                  />
                  <.mini_metric
                    id="exterior-wall-area"
                    label="Exterior wall area"
                    value={unit(@result.measurements.exterior_wall_area_m2, "m²")}
                  />
                </div>
              </.section_card>

              <.section_card
                title="Structure"
                subtitle="Concrete, wall system, and roofing stay separated so you can see where costs are really moving."
              >
                <div class="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
                  <.input
                    field={@form[:concrete_cost_m3_mxn]}
                    type="number"
                    step="10"
                    min="0"
                    label="Concrete cost (MXN/m³)"
                  />
                  <.input
                    field={@form[:rebar_cost_kg_mxn]}
                    type="number"
                    step="1"
                    min="0"
                    label="Rebar cost (MXN/kg)"
                  />
                  <.input
                    field={@form[:rebar_kg_per_m3]}
                    type="number"
                    step="1"
                    min="0"
                    label="Rebar density (kg/m³)"
                  />
                  <.input
                    field={@form[:formwork_allowance_mxn]}
                    type="number"
                    step="100"
                    min="0"
                    label="Formwork allowance (MXN)"
                  />
                  <.input
                    field={@form[:gravel_base_cost_m2_mxn]}
                    type="number"
                    step="10"
                    min="0"
                    label="Gravel/base (MXN/m²)"
                  />
                  <.input
                    field={@form[:foundation_labor_allowance_mxn]}
                    type="number"
                    step="100"
                    min="0"
                    label="Foundation labor (MXN)"
                  />
                  <.input
                    field={@form[:exterior_wall_unit_cost_m2_mxn]}
                    type="number"
                    step="10"
                    min="0"
                    label="Exterior wall material (MXN/m²)"
                  />
                  <.input
                    field={@form[:exterior_wall_labor_cost_m2_mxn]}
                    type="number"
                    step="10"
                    min="0"
                    label="Exterior wall labor (MXN/m²)"
                  />
                  <.input
                    field={@form[:roof_material_cost_m2_mxn]}
                    type="number"
                    step="10"
                    min="0"
                    label="Roof material (MXN/m²)"
                  />
                  <.input
                    field={@form[:roof_waterproofing_cost_m2_mxn]}
                    type="number"
                    step="10"
                    min="0"
                    label="Waterproofing (MXN/m²)"
                  />
                  <.input
                    field={@form[:roof_labor_cost_m2_mxn]}
                    type="number"
                    step="10"
                    min="0"
                    label="Roof labor (MXN/m²)"
                  />
                </div>

                <div class="mt-4 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
                  <.mini_metric
                    id="footing-volume"
                    label="Footing volume"
                    value={unit(@result.measurements.footing_volume_m3, "m³")}
                  />
                  <.mini_metric
                    id="slab-volume"
                    label="Slab volume"
                    value={unit(@result.measurements.slab_volume_m3, "m³")}
                  />
                  <.mini_metric
                    id="foundation-cost"
                    label="Foundation cost"
                    value={money(@result.costs.foundation_mxn, "MXN")}
                  />
                  <.mini_metric
                    id="roof-cost"
                    label="Roof cost"
                    value={money(@result.costs.roof_mxn, "MXN")}
                  />
                </div>
              </.section_card>

              <.section_card
                title="Interior Buildout"
                subtitle="Drywall and metal stud assumptions are editable so the low-cost interior strategy stays explicit."
              >
                <div class="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
                  <.input
                    field={@form[:interior_wall_linear_m]}
                    type="number"
                    step="0.1"
                    min="0"
                    label="Interior wall length (m)"
                  />
                  <.input
                    field={@form[:interior_wall_height_m]}
                    type="number"
                    step="0.1"
                    min="0"
                    label="Interior wall height (m)"
                  />
                  <.input
                    field={@form[:stud_spacing_m]}
                    type="number"
                    step="0.05"
                    min="0.1"
                    label="Stud spacing (m)"
                  />
                  <.input
                    field={@form[:drywall_board_area_m2]}
                    type="number"
                    step="0.01"
                    min="0.1"
                    label="Drywall board size (m²)"
                  />
                  <.input
                    field={@form[:drywall_board_cost_mxn]}
                    type="number"
                    step="10"
                    min="0"
                    label="Drywall board cost (MXN)"
                  />
                  <.input
                    field={@form[:metal_stud_cost_mxn]}
                    type="number"
                    step="10"
                    min="0"
                    label="Metal stud cost (MXN)"
                  />
                  <.input
                    field={@form[:track_cost_mxn]}
                    type="number"
                    step="10"
                    min="0"
                    label="Track cost (MXN)"
                  />
                  <.input
                    field={@form[:track_piece_length_m]}
                    type="number"
                    step="0.1"
                    min="0.1"
                    label="Track piece length (m)"
                  />
                  <.input
                    field={@form[:screws_tape_mud_allowance_mxn]}
                    type="number"
                    step="100"
                    min="0"
                    label="Screws/tape/mud (MXN)"
                  />
                  <.input
                    field={@form[:interior_paint_cost_m2_mxn]}
                    type="number"
                    step="10"
                    min="0"
                    label="Paint (MXN/m²)"
                  />
                  <.input
                    field={@form[:interior_wall_labor_cost_m2_mxn]}
                    type="number"
                    step="10"
                    min="0"
                    label="Labor (MXN/m²)"
                  />
                  <.input
                    field={@form[:paint_allowance_mxn]}
                    type="number"
                    step="100"
                    min="0"
                    label="Other paint allowance (MXN)"
                  />
                  <.input
                    field={@form[:flooring_cost_m2_mxn]}
                    type="number"
                    step="10"
                    min="0"
                    label="Flooring (MXN/m²)"
                  />
                </div>

                <div class="mt-4 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
                  <.mini_metric
                    id="interior-wall-area"
                    label="Drywall area"
                    value={unit(@result.measurements.interior_wall_area_both_sides_m2, "m²")}
                  />
                  <.mini_metric
                    id="stud-count"
                    label="Stud count"
                    value={Integer.to_string(@result.measurements.stud_count_approx)}
                  />
                  <.mini_metric
                    id="drywall-board-count"
                    label="Drywall boards"
                    value={Integer.to_string(@result.measurements.drywall_board_count)}
                  />
                  <.mini_metric
                    id="interior-buildout-cost"
                    label="Interior walls cost"
                    value={money(@result.costs.interior_walls_mxn, "MXN")}
                  />
                </div>
              </.section_card>

              <.section_card
                title="Fixtures"
                subtitle="Bathrooms, kitchen, and openings are the most visible finish costs, so they stay fully editable."
              >
                <div class="grid gap-6 xl:grid-cols-3">
                  <div class="rounded-3xl border border-white/10 bg-white/5 p-4">
                    <h3 class="text-sm font-semibold uppercase tracking-[0.24em] text-slate-200">
                      Bathrooms
                    </h3>
                    <div class="mt-4 grid gap-4">
                      <.input
                        field={@form[:bathroom_count]}
                        type="number"
                        step="1"
                        min="0"
                        label="Bathroom count"
                      />
                      <.input
                        field={@form[:toilet_cost_mxn]}
                        type="number"
                        step="10"
                        min="0"
                        label="Toilet (MXN)"
                      />
                      <.input
                        field={@form[:sink_vanity_cost_mxn]}
                        type="number"
                        step="10"
                        min="0"
                        label="Sink/vanity (MXN)"
                      />
                      <.input
                        field={@form[:shower_cost_mxn]}
                        type="number"
                        step="10"
                        min="0"
                        label="Shower (MXN)"
                      />
                      <.input
                        field={@form[:bathroom_faucet_cost_mxn]}
                        type="number"
                        step="10"
                        min="0"
                        label="Faucet (MXN)"
                      />
                      <.input
                        field={@form[:bathroom_tile_allowance_mxn]}
                        type="number"
                        step="100"
                        min="0"
                        label="Tile allowance (MXN)"
                      />
                      <.input
                        field={@form[:bathroom_plumbing_allowance_mxn]}
                        type="number"
                        step="100"
                        min="0"
                        label="Plumbing allowance (MXN)"
                      />
                      <.input
                        field={@form[:bathroom_labor_allowance_mxn]}
                        type="number"
                        step="100"
                        min="0"
                        label="Labor allowance (MXN)"
                      />
                    </div>
                  </div>

                  <div class="rounded-3xl border border-white/10 bg-white/5 p-4">
                    <h3 class="text-sm font-semibold uppercase tracking-[0.24em] text-slate-200">
                      Kitchen
                    </h3>
                    <div class="mt-4 grid gap-4">
                      <.input
                        field={@form[:kitchen_count]}
                        type="number"
                        step="1"
                        min="0"
                        label="Kitchen count"
                      />
                      <.input
                        field={@form[:cabinet_linear_m_per_kitchen]}
                        type="number"
                        step="0.1"
                        min="0"
                        label="Cabinet run (m)"
                      />
                      <.input
                        field={@form[:cabinet_cost_linear_m_mxn]}
                        type="number"
                        step="10"
                        min="0"
                        label="Cabinets (MXN/m)"
                      />
                      <.input
                        field={@form[:countertop_cost_linear_m_mxn]}
                        type="number"
                        step="10"
                        min="0"
                        label="Countertops (MXN/m)"
                      />
                      <.input
                        field={@form[:kitchen_sink_cost_mxn]}
                        type="number"
                        step="10"
                        min="0"
                        label="Sink (MXN)"
                      />
                      <.input
                        field={@form[:kitchen_faucet_cost_mxn]}
                        type="number"
                        step="10"
                        min="0"
                        label="Faucet (MXN)"
                      />
                      <.input
                        field={@form[:basic_appliance_allowance_mxn]}
                        type="number"
                        step="100"
                        min="0"
                        label="Appliance allowance (MXN)"
                      />
                    </div>
                  </div>

                  <div class="rounded-3xl border border-white/10 bg-white/5 p-4">
                    <h3 class="text-sm font-semibold uppercase tracking-[0.24em] text-slate-200">
                      Electrical, plumbing, doors, windows
                    </h3>
                    <div class="mt-4 grid gap-4">
                      <.input
                        field={@form[:electrical_rough_in_cost_m2_mxn]}
                        type="number"
                        step="10"
                        min="0"
                        label="Electrical rough-in (MXN/m²)"
                      />
                      <.input
                        field={@form[:plumbing_rough_in_allowance_mxn]}
                        type="number"
                        step="100"
                        min="0"
                        label="Plumbing rough-in (MXN)"
                      />
                      <.input
                        field={@form[:main_door_count]}
                        type="number"
                        step="1"
                        min="0"
                        label="Main doors"
                      />
                      <.input
                        field={@form[:main_door_cost_mxn]}
                        type="number"
                        step="10"
                        min="0"
                        label="Main door cost (MXN)"
                      />
                      <.input
                        field={@form[:interior_door_count]}
                        type="number"
                        step="1"
                        min="0"
                        label="Interior doors"
                      />
                      <.input
                        field={@form[:interior_door_cost_mxn]}
                        type="number"
                        step="10"
                        min="0"
                        label="Interior door cost (MXN)"
                      />
                      <.input
                        field={@form[:window_count]}
                        type="number"
                        step="1"
                        min="0"
                        label="Windows"
                      />
                      <.input
                        field={@form[:window_cost_mxn]}
                        type="number"
                        step="10"
                        min="0"
                        label="Window cost (MXN)"
                      />
                    </div>
                  </div>
                </div>
              </.section_card>

              <.section_card
                title="Other Costs"
                subtitle="These softer costs usually get missed first, so they are broken out instead of buried."
              >
                <div class="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
                  <.input
                    field={@form[:permits_design_allowance_mxn]}
                    type="number"
                    step="100"
                    min="0"
                    label="Permits and design (MXN)"
                  />
                  <.input
                    field={@form[:site_preparation_mxn]}
                    type="number"
                    step="100"
                    min="0"
                    label="Site prep (MXN)"
                  />
                  <.input
                    field={@form[:contingency_percent]}
                    type="number"
                    step="0.5"
                    min="0"
                    label="Contingency (%)"
                  />
                  <.input
                    field={@form[:contractor_management_percent]}
                    type="number"
                    step="0.5"
                    min="0"
                    label="Contractor/management (%)"
                  />
                </div>
                <div class="mt-4 flex flex-wrap gap-3">
                  <.button
                    type="button"
                    phx-click="reset"
                    class="btn btn-soft border-white/15 bg-white/10 text-white hover:bg-white/20"
                  >
                    Reset Defaults
                  </.button>
                  <div class="rounded-full border border-amber-300/20 bg-amber-300/10 px-4 py-2 text-sm text-amber-50">
                    Target gap:
                    <span id="target-build-gap" class="font-semibold">
                      {signed_money(@result.comparison.build_cost_gap_cad, "CAD")}
                    </span>
                  </div>
                </div>
              </.section_card>
            </.form>

            <div class="space-y-6 xl:sticky xl:top-24 xl:self-start">
              <.section_card
                title="Results"
                subtitle="This is the current build snapshot using your live inputs."
                card_class="backdrop-blur-xl"
              >
                <div class="grid gap-3 sm:grid-cols-2">
                  <.mini_metric
                    id="total-build-cost-mxn"
                    label="Total build cost"
                    value={money(@result.costs.total_build_cost_mxn, "MXN")}
                  />
                  <.mini_metric
                    id="total-build-cost-cad"
                    label="Total build cost"
                    value={money(@result.costs.total_build_cost_cad, "CAD")}
                  />
                  <.mini_metric
                    id="cost-per-m2-mxn"
                    label="Cost per m²"
                    value={money(@result.costs.cost_per_m2_mxn, "MXN")}
                  />
                  <.mini_metric
                    id="cost-per-m2-cad"
                    label="Cost per m²"
                    value={money(@result.costs.cost_per_m2_cad, "CAD")}
                  />
                  <.mini_metric
                    id="monthly-rent-mxn"
                    label="Tepic monthly rent"
                    value={
                      money_range(
                        @result.inputs.tepic_rent_low_mxn,
                        @result.inputs.tepic_rent_high_mxn,
                        "MXN"
                      )
                    }
                  />
                  <.mini_metric
                    id="monthly-rent-cad"
                    label="Tepic monthly rent"
                    value={
                      money_range(
                        @result.comparison.tepic_monthly_rent_low_cad,
                        @result.comparison.tepic_monthly_rent_high_cad,
                        "CAD"
                      )
                    }
                  />
                  <.mini_metric
                    id="monthly-roi"
                    label="Monthly ROI"
                    value={
                      percent_range(
                        @result.comparison.tepic_monthly_roi_low_percent,
                        @result.comparison.tepic_monthly_roi_high_percent
                      )
                    }
                  />
                  <.mini_metric
                    id="annual-roi"
                    label="Annual ROI"
                    value={
                      percent_range(
                        @result.comparison.tepic_annual_roi_low_percent,
                        @result.comparison.tepic_annual_roi_high_percent
                      )
                    }
                  />
                </div>

                <div class="mt-4 space-y-3 rounded-3xl border border-white/10 bg-slate-950/40 p-4">
                  <.summary_line
                    label="Base build subtotal"
                    value={money(@result.costs.base_total_mxn, "MXN")}
                  />
                  <.summary_line
                    label="Contingency"
                    value={money(@result.costs.contingency_mxn, "MXN")}
                  />
                  <.summary_line
                    label="Contractor / management"
                    value={money(@result.costs.contractor_management_mxn, "MXN")}
                  />
                </div>
              </.section_card>

              <.section_card
                title="Comparison Cards"
                subtitle="The core story: one Canadian property versus a scalable Tepic portfolio."
                card_class="backdrop-blur-xl"
              >
                <div class="space-y-4">
                  <.comparison_card
                    id="canada-comparison-card"
                    title="Canada single property"
                    eyebrow="One expensive asset"
                    cost={money(@result.inputs.canadian_property_cost_cad, "CAD")}
                    rent={
                      money_range(
                        @result.inputs.canadian_rent_low_cad,
                        @result.inputs.canadian_rent_high_cad,
                        "CAD"
                      )
                    }
                    monthly_roi={
                      percent_range(
                        @result.comparison.canada_monthly_roi_low_percent,
                        @result.comparison.canada_monthly_roi_high_percent
                      )
                    }
                    annual_roi={
                      percent_range(
                        @result.comparison.canada_annual_roi_low_percent,
                        @result.comparison.canada_annual_roi_high_percent
                      )
                    }
                    note="Likely stronger liquidity and appreciation, but lower gross yield."
                  />

                  <.comparison_card
                    id="tepic-single-comparison-card"
                    title="Tepic single house"
                    eyebrow="Basic rental build"
                    cost={money(@result.costs.total_build_cost_cad, "CAD")}
                    rent={
                      money_range(
                        @result.comparison.tepic_monthly_rent_low_cad,
                        @result.comparison.tepic_monthly_rent_high_cad,
                        "CAD"
                      )
                    }
                    monthly_roi={
                      percent_range(
                        @result.comparison.tepic_monthly_roi_low_percent,
                        @result.comparison.tepic_monthly_roi_high_percent
                      )
                    }
                    annual_roi={
                      percent_range(
                        @result.comparison.tepic_annual_roi_low_percent,
                        @result.comparison.tepic_annual_roi_high_percent
                      )
                    }
                    note="Lower-cost units can scale cash flow faster when build control stays tight."
                  />

                  <.comparison_card
                    id="tepic-portfolio-comparison-card"
                    title="Same-capital Tepic portfolio"
                    eyebrow={"1 Canadian house vs about #{@result.comparison.target_houses_per_canadian_property} Tepic houses"}
                    cost={Integer.to_string(@result.comparison.houses_per_canadian_property) <> " houses at current inputs"}
                    rent={
                      money_range(
                        @result.comparison.tepic_portfolio_rent_low_cad,
                        @result.comparison.tepic_portfolio_rent_high_cad,
                        "CAD"
                      )
                    }
                    monthly_roi={
                      money_range(
                        @result.comparison.tepic_portfolio_rent_low_mxn,
                        @result.comparison.tepic_portfolio_rent_high_mxn,
                        "MXN"
                      )
                    }
                    annual_roi={
                      money_range(
                        @result.comparison.tepic_portfolio_rent_low_cad * 12,
                        @result.comparison.tepic_portfolio_rent_high_cad * 12,
                        "CAD"
                      )
                    }
                    note="Higher absolute income is the key Tepic insight, even before appreciation is considered."
                  />
                </div>
              </.section_card>

              <.section_card
                title="Assumptions Notes"
                subtitle="Short docs in-app, with the fuller write-up stored under docs/tepic-house-calculator/."
                card_class="backdrop-blur-xl"
              >
                <ul class="space-y-3 text-sm leading-7 text-slate-200">
                  <li>Metric geometry drives wall, roof, slab, and footing quantities.</li>
                  <li>
                    Tepic ROI is gross rent divided by current modeled build cost, with no vacancy, tax, or maintenance deduction in v1.
                  </li>
                  <li>
                    Canadian ROI is gross rent divided by the comparison property value, so the cards stay apples-to-apples on capital deployed.
                  </li>
                  <li>Preset source rows are editable placeholders, not live market quotes.</li>
                </ul>
              </.section_card>

              <.section_card
                title="Preset Cost References"
                subtitle="These rows document the first-pass placeholders carried into the calculator."
                card_class="backdrop-blur-xl"
              >
                <.table id="tepic-cost-source-table" rows={@result.sources}>
                  <:col :let={row} label="Category">{row["category"]}</:col>
                  <:col :let={row} label="Item">{row["item"]}</:col>
                  <:col :let={row} label="Selected source">{row["selected_source"]}</:col>
                  <:col :let={row} label="Unit cost">
                    {money(row["selected_unit_cost_mxn"], "MXN")}
                  </:col>
                  <:col :let={row} label="Notes">{row["notes"]}</:col>
                </.table>
              </.section_card>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  attr :id, :string, required: true
  attr :label, :string, required: true
  attr :value, :string, required: true
  attr :accent, :string, required: true

  defp hero_stat(assigns) do
    ~H"""
    <div
      id={@id}
      class={"overflow-hidden rounded-3xl border border-white/10 bg-gradient-to-br #{@accent} p-4 shadow-lg shadow-sky-950/20"}
    >
      <div class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-200">{@label}</div>
      <div class="mt-2 text-2xl font-semibold text-white">{@value}</div>
    </div>
    """
  end

  attr :title, :string, required: true
  attr :subtitle, :string, required: true
  attr :card_class, :string, default: nil
  slot :inner_block, required: true

  defp section_card(assigns) do
    ~H"""
    <section class={[
      "rounded-[1.75rem] border border-white/10 bg-white/6 p-5 shadow-xl shadow-sky-950/10",
      @card_class
    ]}>
      <div class="mb-5 space-y-2">
        <h2 class="font-serif text-2xl font-semibold tracking-tight text-white">{@title}</h2>
        <p class="max-w-3xl text-sm leading-7 text-slate-300">{@subtitle}</p>
      </div>
      {render_slot(@inner_block)}
    </section>
    """
  end

  attr :id, :string, required: true
  attr :label, :string, required: true
  attr :value, :string, required: true

  defp mini_metric(assigns) do
    ~H"""
    <div id={@id} class="rounded-3xl border border-white/10 bg-slate-950/40 p-4">
      <div class="text-xs font-semibold uppercase tracking-[0.24em] text-slate-400">{@label}</div>
      <div class="mt-2 text-lg font-semibold text-white">{@value}</div>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :value, :string, required: true

  defp summary_line(assigns) do
    ~H"""
    <div class="flex items-center justify-between gap-4 text-sm">
      <span class="text-slate-300">{@label}</span>
      <span class="font-semibold text-white">{@value}</span>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :eyebrow, :string, required: true
  attr :cost, :string, required: true
  attr :rent, :string, required: true
  attr :monthly_roi, :string, required: true
  attr :annual_roi, :string, required: true
  attr :note, :string, required: true

  defp comparison_card(assigns) do
    ~H"""
    <article id={@id} class="rounded-[1.5rem] border border-white/10 bg-slate-950/45 p-5">
      <div class="text-xs font-semibold uppercase tracking-[0.24em] text-sky-200">{@eyebrow}</div>
      <h3 class="mt-2 text-xl font-semibold text-white">{@title}</h3>
      <div class="mt-4 grid gap-3 sm:grid-cols-2">
        <.summary_line label="Capital deployed" value={@cost} />
        <.summary_line label="Monthly rent" value={@rent} />
        <.summary_line label="Monthly ROI" value={@monthly_roi} />
        <.summary_line label="Annual ROI / yearly rent" value={@annual_roi} />
      </div>
      <p class="mt-4 text-sm leading-7 text-slate-300">{@note}</p>
    </article>
    """
  end

  defp assign_result(socket, result) do
    socket
    |> assign(:result, result)
    |> assign(:form, to_form(result.form_inputs, as: :calculator))
  end

  defp money(value, currency) do
    "#{currency} #{format_number(value)}"
  end

  defp signed_money(value, currency) when value < 0 do
    "-#{money(abs(value), currency)}"
  end

  defp signed_money(value, currency), do: "+#{money(value, currency)}"

  defp money_range(low, high, currency) do
    "#{money(low, currency)} - #{money(high, currency)}"
  end

  defp percent_range(low, high) do
    "#{format_number(low, 2)}% - #{format_number(high, 2)}%"
  end

  defp unit(value, suffix) do
    "#{format_number(value)} #{suffix}"
  end

  defp format_number(value, decimals \\ 2) do
    value
    |> Kernel.*(1.0)
    |> :erlang.float_to_binary(decimals: decimals)
    |> split_number()
  end

  defp split_number(number) do
    case String.split(number, ".", parts: 2) do
      [whole, fraction] -> add_delimiter(whole) <> "." <> fraction
      [whole] -> add_delimiter(whole)
    end
  end

  defp add_delimiter("-" <> rest), do: "-" <> add_delimiter(rest)

  defp add_delimiter(number) do
    number
    |> String.reverse()
    |> String.graphemes()
    |> Enum.chunk_every(3)
    |> Enum.map(&Enum.join/1)
    |> Enum.join(",")
    |> String.reverse()
  end
end
