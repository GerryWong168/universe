# Tepic House Calculator Assumptions

This first version is intentionally DB-free and models gross build-cost and rental-yield assumptions only.

## What the calculator does

- Uses metric geometry to derive footprint, perimeter, roof area, wall area, footing volume, and slab volume.
- Applies editable unit costs and allowances to foundation, exterior walls, roof, interior drywall/studs, bathrooms, kitchen, services, and soft costs.
- Converts the final modeled build cost from MXN to CAD with an editable exchange rate.
- Compares Tepic rent yield against a Canadian comparison property using the same capital base.

## Important assumptions

- Tepic ROI is gross rent only.
- Vacancy, maintenance, taxes, insurance, financing, and property management are not deducted in v1.
- Canadian ROI is also shown as gross rent only, so both sides use the same simple basis.
- Preset cost references are placeholders for planning and discussion, not live market quotes.

## Core formulas

```text
footprint_area = length * width
perimeter = 2 * (length + width)
exterior_wall_area = perimeter * wall_height - opening_area
roof_area = footprint_area * roof_factor
footing_volume = (perimeter + interior_footing_length) * footing_width * footing_depth
slab_volume = (footprint_area * floors) * slab_thickness
monthly_roi_percent = monthly_rent_cad / build_cost_cad * 100
annual_roi_percent = (monthly_rent_cad * 12) / build_cost_cad * 100
houses_per_1m = floor(canadian_property_cost_cad / build_cost_cad)
```

## Why the same-capital comparison matters

The point of the Tepic portfolio card is not to predict appreciation. It makes cash-flow scale visible:

- one CAD $1,000,000 Canadian property
- versus many lower-cost Tepic houses funded by the same capital pool

That comparison is what the live page is optimized to surface quickly.
