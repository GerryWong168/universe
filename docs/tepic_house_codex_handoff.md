# Codex Handoff: Tepic House Construction + Rental Yield Web Calculator

## Goal
Move the current Tepic construction-cost and rental-yield spreadsheet model into the existing **Universe** project as a webpage/app tool.

Suggested page name:
- **Tepic House Calculator**

Suggested route:
- `/tools/tepic-house-calculator`
- or wherever Universe keeps real-estate/project tools.

## Current Artifacts
Add these files to the repo or attach/upload them into Codex as context:

1. `tepic_house_construction_cost_calculator.xlsx`
   - Construction cost calculator workbook.
   - Includes editable inputs for dimensions, walls, bathrooms, kitchens, fixtures, etc.
   - Includes three costing source columns where possible: local estimate, Home Depot MX, MercadoLibre.

2. `tepic_vs_canada_rental_yield_complete.xlsx`
   - Rental-yield comparison workbook.
   - Compares Canada/Toronto-style property economics against Tepic/Mexico build-and-rent economics.

## Business Assumptions
Use these as defaults but make them editable in the UI.

### Exchange Rate
- Default exchange rate: **12.5 MXN per 1 CAD**.

### Canada Rental Model
- Property cost: **$1,000,000 CAD**.
- Monthly rent: **$2,500–$3,000 CAD**.
- Gross monthly ROI: `monthly_rent / property_cost`.
- Gross annual ROI: `(monthly_rent * 12) / property_cost`.

### Tepic Rental Model
- Build cost per house: **$50,000 CAD**.
- Monthly rent per Tepic house: **2,500–3,000 MXN**.
- CAD equivalent at 12.5 MXN/CAD:
  - 2,500 MXN = **$200 CAD/month**.
  - 3,000 MXN = **$240 CAD/month**.
- With $1,000,000 CAD, user can build roughly **20 houses**.
- Total rent from 20 Tepic houses:
  - 20 × 2,500 MXN = **50,000 MXN/month = $4,000 CAD/month**.
  - 20 × 3,000 MXN = **60,000 MXN/month = $4,800 CAD/month**.
- Tepic gross annual ROI:
  - One house: roughly **4.8%–5.76%**.
  - Same $1M capital: same yield range, but higher absolute income than one Canadian house.

## Main Insight
For pure rental cash flow:

- Canada: one expensive asset, lower gross yield, likely stronger appreciation/liquidity.
- Tepic: many lower-cost assets, higher gross yield, lower carrying cost, more scalable cash flow.

The webpage should make this obvious with side-by-side output cards.

## Construction Calculator Inputs
Create editable form inputs for these values.

### Geometry
- House length
- House width
- Wall height
- Number of floors, default 1
- Roof pitch / roof waste factor, default 1.10
- Slab thickness
- Footing width
- Footing depth
- Load-bearing interior footing length, optional

### Exterior Walls
- Exterior wall material type
- Exterior wall unit cost
- Exterior wall labor cost
- Window/door opening area deduction

### Interior Walls
Interior walls may use drywall + metal studs to reduce cost.

Inputs:
- Total interior wall linear meters
- Interior wall height
- Stud spacing
- Drywall board size
- Drywall board cost
- Metal stud cost
- Track cost
- Screws/tape/mud allowance
- Paint cost
- Labor cost per m2

### Foundation / Slab / Footing
Inputs:
- Concrete cost per m3
- Rebar cost per kg or per meter
- Formwork allowance
- Gravel/base cost
- Labor cost

### Roof
Inputs:
- Roof type
- Roof area factor
- Roof material cost per m2
- Waterproofing cost per m2
- Labor cost per m2

### Bathrooms
Inputs:
- Number of bathrooms
- Toilet cost
- Sink/vanity cost
- Shower cost
- Faucet cost
- Tile allowance
- Plumbing allowance
- Labor allowance

### Kitchen
Inputs:
- Number of kitchens
- Cabinet linear meters
- Cabinet cost per linear meter
- Countertop cost per linear meter
- Sink cost
- Faucet cost
- Basic appliance allowance, optional

### Electrical / Plumbing / Doors / Windows
Inputs:
- Electrical rough-in cost per m2
- Plumbing rough-in allowance
- Main door count/cost
- Interior door count/cost
- Window count/cost or window m2/cost

### Other Costs
- Permits/design allowance
- Site preparation
- Paint
- Flooring cost per m2
- Contingency percentage
- Contractor/management percentage

## Derived Formulas
Use metric internally where possible.

### Basic Geometry
```text
footprint_area = length * width
perimeter = 2 * (length + width)
exterior_wall_area = perimeter * wall_height - opening_area
roof_area = footprint_area * roof_factor
floor_area = footprint_area * floors
```

### Foundation / Footing
```text
footing_linear_meters = perimeter + load_bearing_interior_footing_length
footing_volume_m3 = footing_linear_meters * footing_width * footing_depth
slab_volume_m3 = floor_area * slab_thickness
```

### Interior Drywall
```text
interior_wall_area_one_side = interior_wall_linear_meters * interior_wall_height
interior_wall_area_both_sides = interior_wall_area_one_side * 2
stud_count_approx = ceil(interior_wall_linear_meters / stud_spacing) + 1
```

### ROI
```text
monthly_rent_cad = monthly_rent_mxn / exchange_rate_mxn_per_cad
annual_rent_cad = monthly_rent_cad * 12
monthly_roi_percent = monthly_rent_cad / build_cost_cad * 100
annual_roi_percent = annual_rent_cad / build_cost_cad * 100
houses_per_1m = floor(1_000_000 / build_cost_cad)
total_monthly_rent_cad = houses_per_1m * monthly_rent_cad
```

## Cost Source Data Model
Cost source rows should support three sources where possible:

1. Local Tepic estimate
2. Home Depot Mexico
3. MercadoLibre Mexico

Recommended fields:

```json
{
  "category": "Bathroom",
  "item": "Toilet",
  "unit": "each",
  "quantity": 1,
  "local_estimate_mxn": 2500,
  "home_depot_mx_mxn": null,
  "mercadolibre_mx_mxn": null,
  "selected_source": "local_estimate",
  "selected_unit_cost_mxn": 2500,
  "url": null,
  "last_checked": null,
  "notes": "Editable placeholder"
}
```

Use editable defaults. Do not hard-code source prices as permanent truth; prices change.

## UI Requirements
Build a clean calculator page with sections:

1. Assumptions
   - Exchange rate
   - Target build cost
   - Rent range

2. House Geometry
   - Length, width, height
   - Auto-calculated area/perimeter

3. Structure
   - Footings
   - Slab
   - Exterior walls
   - Roof

4. Interior Buildout
   - Interior walls
   - Drywall/studs
   - Paint/flooring

5. Fixtures
   - Bathrooms
   - Kitchen
   - Doors/windows

6. Results
   - Total cost MXN
   - Total cost CAD
   - Cost per m2
   - Rent CAD/MXN
   - Monthly ROI
   - Annual ROI
   - Houses possible from $1M CAD
   - Total monthly rent from same $1M capital

7. Comparison Cards
   - Canada single property
   - Tepic single house
   - Tepic 20-house portfolio

## Phoenix / LiveView Implementation Suggestion
Assuming Universe is a Phoenix app:

- Add a LiveView page, e.g. `UniverseWeb.TepicHouseCalculatorLive`.
- Use `~H` templates, not deprecated templates.
- Use existing `core_components.ex` components where available:
  - `<.simple_form>`
  - `<.input>`
  - `<.button>`
  - `<.table>` if present
- Recalculate on `phx-change="recalculate"`.
- Keep the first version DB-free.
- Put formulas in a plain module, e.g. `Universe.RealEstate.TepicCalculator`.
- Put default cost data in `priv/data/tepic_cost_presets.json` or in a module attribute.

## Suggested File Structure
```text
lib/universe/real_estate/tepic_calculator.ex
lib/universe_web/live/tepic_house_calculator_live.ex
priv/data/tepic_cost_presets.json
test/universe/real_estate/tepic_calculator_test.exs
test/universe_web/live/tepic_house_calculator_live_test.exs
docs/tepic_house_calculator.md
```

## Codex Task Prompt
Paste this into Codex:

```text
You are working in my existing Universe project. Build a new webpage tool called "Tepic House Calculator" based on the attached handoff notes and spreadsheets.

Goal:
Create a Phoenix LiveView calculator that estimates the cost to build a basic rental house in Tepic, Mexico, and compares its rental yield against a Canadian $1M rental property.

Defaults:
- Exchange rate: 12.5 MXN per CAD
- Canada property cost: 1,000,000 CAD
- Canada monthly rent range: 2,500–3,000 CAD
- Tepic build cost target: 50,000 CAD per house
- Tepic monthly rent range: 2,500–3,000 MXN
- Same-capital comparison: 1,000,000 CAD buys/builds about 20 Tepic houses

Requirements:
1. Add a route under the Universe project for the calculator.
2. Create a LiveView page using the project's existing layout and core components.
3. Add editable inputs for house length, width, wall height, interior wall length, bathrooms, kitchens, fixtures, flooring, roof, footings, slab, electrical, plumbing, doors, windows, contingency, contractor markup, and exchange rate.
4. Auto-calculate footprint area, perimeter, exterior wall area, roof area, footing volume, slab volume, drywall area, total cost MXN, total cost CAD, monthly ROI, annual ROI, cost per m2, and same-capital rental comparison.
5. Put formulas in a testable plain Elixir module.
6. Add tests for the calculator formulas.
7. Keep the first implementation DB-free.
8. Use sensible editable default cost values. Do not claim source prices are current unless stored with `last_checked` and source URLs.
9. Add a small docs page explaining assumptions and formulas.
10. Open a PR/branch with the implementation.
```

## First Version Acceptance Criteria
- User can edit dimensions and immediately see cost changes.
- User can edit exchange rate and immediately see MXN/CAD changes.
- User can edit bathrooms/kitchens/interior walls and see cost changes.
- User sees Canada vs Tepic vs Tepic-portfolio yield comparison.
- Default model should land near the existing target: about **$50k CAD** for a basic Tepic rental house, depending on inputs.
