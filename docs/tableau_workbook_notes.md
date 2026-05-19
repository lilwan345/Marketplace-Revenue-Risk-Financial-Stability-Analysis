# Tableau Workbook Notes

The repository includes a generated Tableau packaged workbook:

`tableau_workbook/Marketplace_Revenue_Risk_Dashboard.twbx`

## What Is Included

- Bundled CSV data sources from `tableau_data/`
- A `Client Overview` dashboard tab with a polished client-facing snapshot from `dashboard.html`
- Native Tableau worksheets for KPI cards, revenue trend, MoM growth, state concentration, customer deciles, Lorenz curve, payment structure, installment distribution, and action plan
- Five dashboard tabs:
  - Client Overview
  - Executive Risk Overview
  - Revenue Stability
  - Concentration Risk
  - Liquidity & Action Plan

## How To Open

Open the `.twbx` file directly in Tableau Desktop:

```text
tableau_workbook/Marketplace_Revenue_Risk_Dashboard.twbx
```

The workbook is packaged, so the CSV files are embedded inside the `.twbx` and should not require reconnecting to local data.

Open `Client Overview` first when presenting to a non-technical audience. It is designed as the readable executive view, while the native Tableau sheets remain available for drill-down and validation.

## How To Rebuild

Run the export script first, then rebuild the Tableau workbook:

```r
Rscript export_tableau_data.R
Rscript build_tableau_workbook.R
```

## Suggested Final Polish In Tableau

The workbook is generated from code so it can be version-controlled and rebuilt. For a final Tableau Public submission, open the `.twbx` and apply final visual polish in Tableau Desktop:

- Use `Fit Entire View` for each dashboard sheet.
- Format revenue as BRL and shares as percentages.
- Increase KPI card font size on `KPI Cards`.
- Apply the risk color palette from `docs/tableau_dashboard_blueprint.md`.
- Hide unneeded worksheet tabs before publishing.
- Use the HTML prototype at `dashboard.html` as the visual reference for the final client-facing layout.
