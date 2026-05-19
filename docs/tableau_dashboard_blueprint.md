# Tableau Dashboard Blueprint

This blueprint translates the technical revenue-risk analysis into a client-facing dashboard experience. The goal is to help a non-technical stakeholder understand the business risk quickly, then explore the evidence behind each risk.

## Dashboard Story

**Main question:** Is marketplace revenue financially stable enough to support confident planning?

**Short answer:** Revenue is growing, and four observable patterns shape planning confidence: volatile monthly revenue, high dependence on São Paulo, concentrated high-value customer revenue, and an installment-heavy payment mix that lengthens the working-capital cycle.

## Suggested Workbook Structure

Build the Tableau workbook with four dashboard tabs:

1. Executive Risk Overview
2. Revenue Stability
3. Concentration Risk
4. Cash Flow Timing & Action Plan

Use the CSV files in `tableau_data/` as separate data sources. They are already aggregated and do not need joins for the suggested views.

## Tab 1: Executive Risk Overview

**Purpose:** Give the client the answer in under 30 seconds.

**Data source:** `tableau_data/kpi_summary.csv`

**Views to create:**

| View | Fields | Tableau setup |
|---|---|---|
| KPI risk cards | `risk_dimension`, `display_value`, `risk_level`, `client_explanation` | Use `risk_dimension` as card title, `display_value` as large text, color by `risk_level` |
| Patterns-to-monitor list | `risk_dimension`, `recommended_action` | Text table or compact pattern cards sorted by `sort_order` |

**Suggested risk colors:**

| Risk level | Color |
|---|---|
| Low | `#2E7D32` |
| Moderate | `#F2A541` |
| Elevated | `#C84C4C` |

**Client-facing headline:**

> Revenue is scaling, and four risk dimensions shape the planning-confidence picture: revenue stability, geographic concentration, customer concentration, and cash-flow timing.

**Tooltip template:**

```text
<Risk Dimension>
Metric: <Display Value>
Risk level: <Risk Level>

What this means:
<Client Explanation>

Pattern to monitor:
<Recommended Action>
```

## Tab 2: Revenue Stability

**Purpose:** Explain whether revenue is predictable enough for planning.

**Data source:** `tableau_data/monthly_revenue.csv`

**Views to create:**

| View | Fields | Tableau setup |
|---|---|---|
| Monthly revenue trend | `month`, `monthly_revenue` | Line chart, format revenue as BRL |
| Month-over-month growth | `month`, `mom_growth`, `growth_direction` | Bar chart, color positive and negative bars differently |
| Volatility signal table | `month`, `monthly_revenue`, `mom_growth`, `volatility_signal` | Compact table filtered to `High swing` months |

**Calculated field: MoM Growth Label**

```text
STR(ROUND([mom_growth] * 100, 1)) + "%"
```

**Tooltip template:**

```text
Month: <Month>
Revenue: R$ <Monthly Revenue>
MoM growth: <MoM Growth Label>
Signal: <Volatility Signal>

Interpretation:
Large swings make short-term cash flow harder to forecast, even when the long-term trend is positive.
```

## Tab 3: Concentration Risk

**Purpose:** Show where revenue dependency exists and how severe it is.

**Data sources:**

- `tableau_data/state_revenue.csv`
- `tableau_data/customer_decile_summary.csv`
- `tableau_data/customer_lorenz_curve.csv`

**Views to create:**

| View | Fields | Tableau setup |
|---|---|---|
| Revenue by state | `customer_state`, `revenue_share`, `concentration_tier` | Horizontal bar chart sorted descending |
| State concentration ranking | `customer_state`, `total_revenue`, `state_rank` | Table or label beside the bar chart |
| Revenue by customer decile | `segment_label`, `revenue_share` | Bar chart, highlight Decile 1 |
| Lorenz curve | `cumulative_customer_share`, `cumulative_revenue_share` | Line chart; add diagonal equality reference line |

**Suggested interaction:**

Use dashboard highlight actions so clicking a state or decile visually emphasizes the related concentration tier.

**Client-facing annotation for state chart:**

> SP alone contributes about 37% of revenue, so regional issues in one state could materially affect total revenue.

**Client-facing annotation for decile chart:**

> The top customer decile contributes about 38% of revenue, creating retention risk among the highest-value buyers.

## Tab 4: Cash Flow Timing & Action Plan

**Purpose:** Translate payment-mix behavior into a cash-flow timing view.

**Data sources:**

- `tableau_data/payment_summary.csv`
- `tableau_data/installment_distribution.csv`
- `tableau_data/action_plan.csv`

**Views to create:**

| View | Fields | Tableau setup |
|---|---|---|
| Revenue by payment structure | `payment_structure`, `revenue_share` | Donut chart or two-bar comparison |
| Installment count distribution | `max_installments`, `revenue_share` | Bar chart sorted by installment count |
| Action plan | `priority`, `action_area`, `suggested_intervention`, `success_metric` | Text table sorted by `priority` |

**Optional Tableau parameter: Installment-Share Scenario**

Create a parameter named `Installment Revenue Reduction` to let users explore how a hypothetical shift in payment mix would affect the cash-timing view:

| Setting | Value |
|---|---|
| Data type | Float |
| Current value | 0.10 |
| Allowable values | Range |
| Minimum | 0 |
| Maximum | 0.25 |
| Step size | 0.05 |

**Calculated field: Scenario Installment Revenue Share**

```text
IF [payment_structure] = "Installment" THEN
    [revenue_share] - [Installment Revenue Reduction]
ELSE
    [revenue_share] + [Installment Revenue Reduction]
END
```

**Client-facing interpretation:**

> A 10 percentage-point shift from installment-paid revenue to upfront-paid revenue would compress the working-capital cycle by a proportional amount; the parameter is a what-if lens, not a prescribed target.

## Layout Guidance

- Use an executive summary first, not a data exploration page first.
- Put KPI cards at the top and supporting charts below.
- Keep all chart titles in business language, not technical language.
- Use tooltips to explain CV, HHI, and Gini instead of putting long definitions on the dashboard canvas.
- Use annotations only for the highest-impact findings: SP dependency, top-decile customer dependency, and installment revenue share.
- Avoid showing SQL/R details in the Tableau dashboard. Keep those in the GitHub report as the technical appendix.

## Suggested Final Tableau Public Title

**Marketplace Revenue Risk Dashboard: Stability, Concentration, and Cash-Flow Timing**

## Suggested Tableau Public Description

This dashboard converts 99,442 Brazilian e-commerce orders (2017–2018) into a client-facing financial risk view. It surfaces revenue volatility, geographic concentration, customer-revenue inequality, and cash-flow timing patterns driven by installment-heavy payments, then links each pattern to a metric the business can monitor.
