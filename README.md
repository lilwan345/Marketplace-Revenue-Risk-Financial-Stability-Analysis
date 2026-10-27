# Marketplace Revenue Risk: Olist

[![Dashboard](https://img.shields.io/badge/dashboard-live-0f766e)](https://lilwan345.github.io/Marketplace-Revenue-Risk-Financial-Stability-Analysis/dashboard.html)
[![Report](https://img.shields.io/badge/report-HTML-336791)](https://lilwan345.github.io/Marketplace-Revenue-Risk-Financial-Stability-Analysis/)
[![MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE)

How steady is a marketplace's revenue, how much of it depends on a few places
and a few big orders, and how long does the money take to arrive? I measured
all four on **96,477 delivered orders from Olist**, a Brazilian online
marketplace (2016–2018), using SQL (PostgreSQL) and R, and put the results in
a small dashboard that runs in the browser.

**[Open the dashboard](https://lilwan345.github.io/Marketplace-Revenue-Risk-Financial-Stability-Analysis/dashboard.html)** ·
**[Read the full report](https://lilwan345.github.io/Marketplace-Revenue-Risk-Financial-Stability-Analysis/)**

| Monthly revenue, 2017–2018 | How concentrated revenue is (Lorenz curve) |
|---|---|
| ![Monthly revenue climbs steeply through 2017, then levels off near one million reais a month in 2018](assets/monthly_revenue_trend.png) | ![The Lorenz curve bows well below the equality line: a small share of orders brings in a large share of revenue](assets/customer_lorenz_curve.png) |

## What I found

| Risk | Measure | Result | In plain words |
|---|---|---|---|
| **Revenue swings** | Coefficient of variation (CV) of monthly revenue | 0.42 | Monthly revenue moves around a lot. But Olist was still growing fast in 2017, and growth alone makes this number look bigger. With the growth trend taken out, month-to-month swings are smaller (growth volatility 0.32). |
| **Depends on one state** | Each state's share of revenue | São Paulo 37%, Rio 13%, Minas Gerais 12% | More than a third of revenue comes from one state. |
| **Depends on big orders** | Share of revenue from the top 10% of orders; Gini | 38%; Gini 0.475 | The top 10% bring in 38% of revenue, the top 30% about 64%. (See the note below on what "customer" means here.) |
| **Money arrives late** | Share of revenue paid in installments | about 64%, averaging 4.12 installments | Most revenue is paid over several months, so cash comes in well after the sale. Brazilian shoppers are used to up to 12 interest-free installments, so 4.12 is not high; what matters is how much revenue is paid this way. |

**What the measures mean**

- **CV**: the standard deviation of monthly revenue divided by its average.
  0 means every month is the same; higher means bumpier.
- **Gini**: 0 means every order is the same size, 1 means one order is
  everything.
- **HHI** (in the report): add up the squares of each state's revenue share.
  It is 0.18 here; 1 would mean all revenue comes from a single state. I use it
  only to describe the spread, not against any official threshold.

### A note on "customers"

Olist gives every order its own `customer_id`; the ID that follows a real person
across orders is `customer_unique_id`. My SQL groups by `customer_id`, so the
"customer" deciles in the dashboard and report really rank **orders** by value.
Almost all Olist buyers order only once (about 97%), so the picture is close,
but grouping by `customer_unique_id` is the correct version and the next fix.

## The dashboard

[`dashboard.html`](dashboard.html) is one HTML file (plain JavaScript and SVG,
no libraries) that reads eight small CSV files from [`data/`](data/): the KPI
cards, monthly revenue, revenue by state, the decile summary, the Lorenz
curve, the payment mix, the installment distribution and a short action list.
Anyone can open the same CSVs in Excel or a BI tool.

## How it works

1. **SQL (PostgreSQL)** builds one clean table of delivered orders (order
   value, state, installments), then views for revenue by state, by month and by
   decile ([`project.sql`](project.sql)). Deciles use `NTILE(10)`.
2. **R** ([`Analysis.Rmd`](Analysis.Rmd)) computes the four measures, the
   growth-adjusted swing numbers, and the charts (ggplot2), and renders the
   report.
3. **The dashboard** reads the exported CSVs.

## Run it

**Just the dashboard:** the CSVs are already in the repo.

```bash
python3 -m http.server     # then open http://localhost:8000/dashboard.html
```

Opened straight from disk, the dashboard falls back to a built-in copy of the
same data; `python3 tools/sync_dashboard_fallback.py` keeps that copy in sync
with `data/`.

**The whole analysis** (needs PostgreSQL and R):

1. Download `olist_orders_dataset.csv`, `olist_customers_dataset.csv` and
   `olist_order_payments_dataset.csv` from
   [Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) and
   load them into PostgreSQL as tables with the same names (without `.csv`).
2. Run [`project.sql`](project.sql) to create the views.
3. Set `PG_PASSWORD` (and, if yours differ from the defaults in
   `Analysis.Rmd`, `OLIST_DB_NAME`, `OLIST_DB_HOST`, `OLIST_DB_PORT`,
   `OLIST_DB_USER`).
4. Render the report:

   ```r
   Rscript -e 'rmarkdown::render("Analysis.Rmd", output_file = "index.html")'
   ```

   R packages: `DBI`, `RPostgres`, `ggplot2`, `dplyr`, `ineq`.

## Files

```
project.sql       SQL views: clean orders, revenue by state, month and decile
Analysis.Rmd      the analysis in R; renders index.html (the report)
dashboard.html    the browser dashboard
data/             the eight CSVs the dashboard reads
tools/            sync_dashboard_fallback.py (keeps the dashboard's offline copy in sync)
assets/           the two charts above
```

## Data

[Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce):
99,441 orders placed between September 2016 and October 2018. I keep the 96,477
that were delivered and have payment records. The monthly charts and the swing
numbers start in January 2017, because 2016 has only a few sparse months, and
the last full month of delivered orders is August 2018.

The numbers describe this marketplace in this period. Installment habits in
particular are Brazilian, so they shouldn't be compared directly with U.S.
benchmarks.

---

Built by **Liyuan Wan** · [GitHub](https://github.com/lilwan345)
