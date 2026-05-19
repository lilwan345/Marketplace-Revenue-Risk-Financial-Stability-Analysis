# Marketplace Revenue Risk & Financial Stability Analysis

> Quantifying financial concentration and liquidity risk across 100,000+ e-commerce transactions using SQL and R.

**Client dashboard package:** [`tableau_data/`](tableau_data/) + [Tableau Dashboard Blueprint](docs/tableau_dashboard_blueprint.md)  
**Technical report:** [View Full Interactive Report](https://lilwan345.github.io/Marketplace-Revenue-Risk-Financial-Stability-Analysis/)

---

## What This Project Does

This project builds a financial risk assessment framework on top of the Brazilian E-Commerce Public Dataset (Olist, 2016–2018). It identifies and quantifies four dimensions of revenue risk that matter to marketplace businesses, then packages the results into Tableau-ready datasets for a client-facing dashboard.

| Risk Dimension | Key Metric | Finding |
|---|---|---|
| Revenue Stability | CV = 0.42 | Moderate volatility; unstable short-term growth |
| Geographic Concentration | HHI = 0.18 | São Paulo alone drives 37% of total revenue |
| Customer Concentration | Gini ≈ 0.48 | Top 10% of customers contribute 38% of revenue |
| Liquidity Risk | Avg. Installments = 4.12 | Installment-heavy structure delays cash collection |

> Bottom line: Based on findings, three targeted interventions are recommended: promotional calendar optimization to address revenue volatility, seller recruitment in MG and PR to reduce geographic concentration, and a loyalty program targeting the top customer decile to stabilize high-value revenue.
---

## Tableau Dashboard Package

The repository includes a Tableau-ready dashboard package designed for non-technical clients and business stakeholders.

| Asset | Purpose |
|---|---|
| [`export_tableau_data.R`](export_tableau_data.R) | Rebuilds the dashboard CSV files directly from the raw Olist datasets |
| [`tableau_data/monthly_revenue.csv`](tableau_data/monthly_revenue.csv) | Monthly revenue trend, MoM growth, and volatility flags |
| [`tableau_data/state_revenue.csv`](tableau_data/state_revenue.csv) | State-level revenue concentration and ranking |
| [`tableau_data/customer_decile_summary.csv`](tableau_data/customer_decile_summary.csv) | Revenue concentration by customer decile |
| [`tableau_data/customer_lorenz_curve.csv`](tableau_data/customer_lorenz_curve.csv) | Lorenz curve points for customer concentration |
| [`tableau_data/payment_summary.csv`](tableau_data/payment_summary.csv) | One-time vs installment revenue exposure |
| [`tableau_data/installment_distribution.csv`](tableau_data/installment_distribution.csv) | Revenue distribution by installment count |
| [`tableau_data/kpi_summary.csv`](tableau_data/kpi_summary.csv) | Executive KPI cards with client-friendly explanations |
| [`tableau_data/action_plan.csv`](tableau_data/action_plan.csv) | Recommended actions and success metrics |

Recommended Tableau workbook tabs:

1. **Executive Risk Overview**: KPI cards, risk levels, and recommended actions
2. **Revenue Stability**: monthly revenue trend, MoM growth, and volatility signals
3. **Concentration Risk**: state concentration, customer deciles, and Lorenz curve
4. **Liquidity & Action Plan**: installment exposure and practical interventions

See the full build guide in [docs/tableau_dashboard_blueprint.md](docs/tableau_dashboard_blueprint.md) and the field definitions in [docs/tableau_data_dictionary.md](docs/tableau_data_dictionary.md).

To regenerate the Tableau datasets:

```r
Rscript export_tableau_data.R
```

## Key Findings

- **Revenue is volatile short-term**: CV of 0.42 and highly uneven month-over-month growth signal unstable performance, despite an overall upward trend from 2017 to 2018.
- **São Paulo dominates geographically**: SP contributes ~37% of revenue, followed by RJ (~13%) and MG (~12%). HHI of 0.18 indicates moderate but meaningful concentration risk.
- **A small customer base drives most revenue**: The top decile alone accounts for 38% of revenue; the top 3 deciles contribute ~64%. The Lorenz curve and Gini coefficient confirm high inequality.
- **Installment payments create liquidity lag**: Over 60% of revenue comes from installment orders, with an average of 4.12 installments per order — meaning cash is collected gradually, not upfront.

---

## Tools & Methods

**SQL (PostgreSQL)**
- Constructed modular views for financial orders, state revenue, customer deciles, and payment structure
- Applied window functions (NTILE, SUM OVER) for segmentation and ranking

**R (RMarkdown)**
- Calculated CV, HHI, Gini coefficient, and weighted installment count
- Visualized trends with ggplot2: line charts, bar charts, and Lorenz curve

**Tableau-ready packaging**
- Exported client-facing KPI, trend, concentration, liquidity, and action-plan datasets
- Added dashboard blueprint, tooltip copy, chart mapping, and field dictionary

---

## Project Structure

```
├── Analysis.Rmd          # Main analysis (R Markdown source)
├── index.html            # Rendered GitHub Pages report
├── project.sql           # SQL views for data preparation
├── analysis.R            # Standalone R script
├── export_tableau_data.R # Tableau CSV export script
├── docs/
│   ├── tableau_dashboard_blueprint.md
│   └── tableau_data_dictionary.md
├── tableau_data/
│   ├── kpi_summary.csv
│   ├── monthly_revenue.csv
│   ├── state_revenue.csv
│   ├── customer_decile_summary.csv
│   ├── customer_lorenz_curve.csv
│   ├── payment_summary.csv
│   ├── installment_distribution.csv
│   └── action_plan.csv
├── olist_customers_dataset.csv
├── olist_orders_dataset.csv
└── olist_order_payments_dataset.csv
```

---

## Data Source

[Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) — ~100,000 orders from 2016 to 2018, covering order details, customer locations, and payment structures.

> **Note:** This dataset reflects 2016–2018 Brazilian e-commerce operations. Findings are specific to this time period and market context.

---

## Author

**Liyuan Wan** · [GitHub](https://github.com/lilwan345)
