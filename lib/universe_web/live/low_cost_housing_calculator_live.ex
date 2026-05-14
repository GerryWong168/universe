defmodule UniverseWeb.LowCostHousingCalculatorLive do
  use UniverseWeb, :live_view

  alias Universe.RealEstate.LowCostHousingCalculator

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, LowCostHousingCalculator.title())
     |> assign_result(LowCostHousingCalculator.calculate())}
  end

  @impl true
  def handle_event("recalculate", %{"calculator" => params}, socket) do
    {:noreply, assign_result(socket, LowCostHousingCalculator.calculate(params))}
  end

  @impl true
  def handle_event("reset", _params, socket) do
    {:noreply, assign_result(socket, LowCostHousingCalculator.calculate())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} variant={:tool}>
      <div
        id="low-cost-housing-page"
        class="min-h-screen rounded-[2rem] border border-amber-950/20 bg-[radial-gradient(circle_at_top_left,_rgba(251,191,36,0.16),_transparent_32%),linear-gradient(145deg,_#431407,_#78350f_38%,_#111827)] px-4 py-8 text-amber-50 shadow-2xl shadow-amber-950/20 sm:px-6 lg:px-8"
      >
        <div class="w-full space-y-8">
          <section class="grid gap-6 xl:grid-cols-[1.2fr_0.8fr] xl:items-end">
            <div class="space-y-4">
              <div class="inline-flex items-center gap-2 rounded-full border border-amber-200/20 bg-amber-200/10 px-3 py-1 text-xs font-semibold uppercase tracking-[0.28em] text-amber-100">
                <.icon name="hero-table-cells" class="size-4" /> Spreadsheet Page
              </div>
              <div class="space-y-3">
                <h1 class="max-w-4xl font-serif text-4xl font-semibold tracking-tight text-white sm:text-5xl">
                  {@result.title}
                </h1>
                <p class="max-w-4xl text-sm leading-7 text-amber-100/90 sm:text-base">
                  {@result.description}
                </p>
                <.link
                  href={@result.source_url}
                  class="inline-flex items-center gap-2 text-sm font-semibold text-amber-200 underline decoration-amber-200/40 underline-offset-4 hover:text-white"
                >
                  Open original Google Sheet
                  <.icon name="hero-arrow-top-right-on-square" class="size-4" />
                </.link>
              </div>
            </div>

            <div class="grid gap-3 sm:grid-cols-3">
              <.hero_stat
                id="low-cost-total-mxn"
                label="Total modeled cost"
                value={money(@result.summary.total_cost_mxn, "MXN")}
              />
              <.hero_stat
                id="low-cost-profit-mxn"
                label="Projected profit"
                value={money(@result.summary.profit_mxn, "MXN")}
              />
              <.hero_stat
                id="low-cost-margin"
                label="Gross margin"
                value={percent(@result.summary.gross_margin_percent)}
              />
            </div>
          </section>

          <div class="grid gap-8 xl:grid-cols-[1.05fr_0.95fr]">
            <.form
              for={@form}
              id="low-cost-housing-form"
              phx-change="recalculate"
              class="space-y-6"
            >
              <.section_card
                title="Assumptions"
                subtitle="These boxes are prefilled from the original spreadsheet assumptions and stay editable on-page."
              >
                <div class="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
                  <.input field={@form[:width_m]} type="number" step="0.1" min="0" label="Width (m)" />
                  <.input
                    field={@form[:length_m]}
                    type="number"
                    step="0.1"
                    min="0"
                    label="Length (m)"
                  />
                  <.input field={@form[:unit_count]} type="number" step="1" min="1" label="Homes" />
                  <.input
                    field={@form[:land_area_m2]}
                    type="number"
                    step="0.1"
                    min="0"
                    label="Land area (m²)"
                  />
                  <.input
                    field={@form[:land_price_mxn_per_m2]}
                    type="number"
                    step="10"
                    min="0"
                    label="Land price (MXN/m²)"
                  />
                  <.input
                    field={@form[:foundation_cost_mxn]}
                    type="number"
                    step="10"
                    min="0"
                    label="Foundation subtotal (MXN)"
                  />
                  <.input
                    field={@form[:lock_up_cost_mxn]}
                    type="number"
                    step="10"
                    min="0"
                    label="Lock up subtotal (MXN)"
                  />
                  <.input
                    field={@form[:finishing_cost_mxn]}
                    type="number"
                    step="10"
                    min="0"
                    label="Finishing subtotal (MXN)"
                  />
                  <.input
                    field={@form[:contingency_percent]}
                    type="number"
                    step="0.5"
                    min="0"
                    label="Contingency (%)"
                  />
                  <.input
                    field={@form[:sale_price_mxn]}
                    type="number"
                    step="1000"
                    min="0"
                    label="Sale price (MXN)"
                  />
                  <.input
                    field={@form[:cad_per_1000_mxn]}
                    type="number"
                    step="1"
                    min="0"
                    label="CAD per 1,000 MXN"
                  />
                  <.input
                    field={@form[:usd_per_1000_mxn]}
                    type="number"
                    step="1"
                    min="0"
                    label="USD per 1,000 MXN"
                  />
                  <.input
                    field={@form[:build_months]}
                    type="number"
                    step="0.1"
                    min="0.1"
                    label="Build horizon (months)"
                  />
                </div>

                <div class="mt-4 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
                  <.mini_metric
                    id="low-cost-footprint"
                    label="Footprint area"
                    value={unit(@result.summary.footprint_area_m2, "m²")}
                  />
                  <.mini_metric
                    id="low-cost-unit-area"
                    label="Area per home"
                    value={unit(@result.summary.per_unit_area_m2, "m²")}
                  />
                  <.mini_metric
                    id="low-cost-sale-per-unit"
                    label="Sale per home"
                    value={money(@result.summary.sale_per_unit_mxn, "MXN")}
                  />
                  <.mini_metric
                    id="low-cost-cost-per-unit"
                    label="Modeled cost per home"
                    value={money(@result.summary.cost_per_unit_mxn, "MXN")}
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
                  <div class="rounded-full border border-amber-200/20 bg-amber-200/10 px-4 py-2 text-sm text-amber-50">
                    Source title from cell A1: <span class="font-semibold">{@result.title}</span>
                  </div>
                </div>
              </.section_card>

              <.section_card
                title="Original Sheet Snapshot"
                subtitle="Key line items from the shared spreadsheet are preserved here as a reference table."
              >
                <.table id="low-cost-line-items-table" rows={@result.line_items}>
                  <:col :let={row} label="Phase">{row.phase}</:col>
                  <:col :let={row} label="Item">{row.item}</:col>
                  <:col :let={row} label="Unit">{row.unit}</:col>
                  <:col :let={row} label="Qty">{format_number(row.quantity)}</:col>
                  <:col :let={row} label="Unit cost">{money(row.unit_cost_mxn, "MXN")}</:col>
                  <:col :let={row} label="Line total">{money(row.total_mxn, "MXN")}</:col>
                </.table>
              </.section_card>
            </.form>

            <div class="space-y-6 xl:sticky xl:top-24 xl:self-start">
              <.section_card
                title="Modeled Results"
                subtitle="High-level outputs based on the editable assumptions on the left."
                card_class="backdrop-blur-xl"
              >
                <div class="grid gap-3 sm:grid-cols-2">
                  <.mini_metric
                    id="low-cost-land-cost"
                    label="Land cost"
                    value={money(@result.summary.land_cost_mxn, "MXN")}
                  />
                  <.mini_metric
                    id="low-cost-construction"
                    label="Construction subtotal"
                    value={money(@result.summary.base_construction_cost_mxn, "MXN")}
                  />
                  <.mini_metric
                    id="low-cost-contingency"
                    label="Contingency"
                    value={money(@result.summary.contingency_mxn, "MXN")}
                  />
                  <.mini_metric
                    id="low-cost-total-cost"
                    label="Total project cost"
                    value={money(@result.summary.total_cost_mxn, "MXN")}
                  />
                  <.mini_metric
                    id="low-cost-total-cost-cad"
                    label="Total project cost"
                    value={money(@result.summary.total_cost_cad, "CAD")}
                  />
                  <.mini_metric
                    id="low-cost-total-cost-usd"
                    label="Total project cost"
                    value={money(@result.summary.total_cost_usd, "USD")}
                  />
                  <.mini_metric
                    id="low-cost-sale-price"
                    label="Sale price"
                    value={money(@result.inputs.sale_price_mxn, "MXN")}
                  />
                  <.mini_metric
                    id="low-cost-monthly-profit"
                    label="Profit per build month"
                    value={money(@result.summary.project_monthly_profit_mxn, "MXN")}
                  />
                </div>

                <div class="mt-4 space-y-3 rounded-3xl border border-white/10 bg-slate-950/40 p-4">
                  <.summary_line
                    label="Projected profit"
                    value={money(@result.summary.profit_mxn, "MXN")}
                  />
                  <.summary_line
                    label="Projected profit (CAD)"
                    value={money(@result.summary.profit_cad, "CAD")}
                  />
                  <.summary_line
                    label="Sale value (CAD)"
                    value={money(@result.summary.sale_price_cad, "CAD")}
                  />
                  <.summary_line
                    label="Sale value (USD)"
                    value={money(@result.summary.sale_price_usd, "USD")}
                  />
                </div>
              </.section_card>

              <.section_card
                title="Phase Totals"
                subtitle="This keeps the spreadsheet's construction story legible without forcing users through the whole raw grid."
                card_class="backdrop-blur-xl"
              >
                <.table id="low-cost-phase-table" rows={@result.phase_rows}>
                  <:col :let={row} label="Phase">{row.phase}</:col>
                  <:col :let={row} label="Subtotal">{money(row.subtotal_mxn, "MXN")}</:col>
                  <:col :let={row} label="Notes">{row.note}</:col>
                </.table>
              </.section_card>

              <.section_card
                title="Canadian Forecast Snapshot"
                subtitle="The original spreadsheet also modeled how repeated projects compound over time."
                card_class="backdrop-blur-xl"
              >
                <.table id="low-cost-forecast-table" rows={@result.forecast_rows}>
                  <:col :let={row} label="Period">{row.period}</:col>
                  <:col :let={row} label="Years">{format_number(row.years)}</:col>
                  <:col :let={row} label="Homes">{row.homes}</:col>
                  <:col :let={row} label="Cumulative cost">{money(row.cumulative_cost, "MXN")}</:col>
                  <:col :let={row} label="Sale value">{money(row.sale_value, "MXN")}</:col>
                  <:col :let={row} label="Profit">{money(row.monthly_profit, "MXN")}</:col>
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

  defp hero_stat(assigns) do
    ~H"""
    <div
      id={@id}
      class="overflow-hidden rounded-3xl border border-white/10 bg-white/8 p-4 shadow-lg shadow-amber-950/20"
    >
      <div class="text-xs font-semibold uppercase tracking-[0.24em] text-amber-200">{@label}</div>
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
      "rounded-[1.75rem] border border-white/10 bg-white/6 p-5 shadow-xl shadow-amber-950/10",
      @card_class
    ]}>
      <div class="mb-5 space-y-2">
        <h2 class="font-serif text-2xl font-semibold tracking-tight text-white">{@title}</h2>
        <p class="max-w-3xl text-sm leading-7 text-amber-50/80">{@subtitle}</p>
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
      <div class="text-xs font-semibold uppercase tracking-[0.24em] text-amber-100/60">{@label}</div>
      <div class="mt-2 text-lg font-semibold text-white">{@value}</div>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :value, :string, required: true

  defp summary_line(assigns) do
    ~H"""
    <div class="flex items-center justify-between gap-4 text-sm">
      <span class="text-amber-50/80">{@label}</span>
      <span class="font-semibold text-white">{@value}</span>
    </div>
    """
  end

  defp assign_result(socket, result) do
    socket
    |> assign(:result, result)
    |> assign(:form, to_form(result.form_inputs, as: :calculator))
  end

  defp money(value, currency), do: "#{currency} #{format_number(value)}"
  defp percent(value), do: "#{format_number(value, 2)}%"
  defp unit(value, suffix), do: "#{format_number(value)} #{suffix}"

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
