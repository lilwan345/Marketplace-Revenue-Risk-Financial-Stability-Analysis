# Tableau Data Dictionary

The files in `tableau_data/` are designed for Tableau dashboards. Each file is already aggregated for a specific dashboard view, so Tableau does not need to run heavy joins or calculations.

## monthly_revenue.csv

Monthly revenue trend and month-over-month growth.

| Field | Meaning |
|---|---|
| `month` | First day of the revenue month |
| `monthly_revenue` | Total delivered-order revenue in BRL |
| `mom_growth` | Month-over-month revenue growth rate |
| `growth_direction` | `Growth`, `Decline`, or `Baseline` |
| `volatility_signal` | Flags months with large swings |

## state_revenue.csv

State-level revenue concentration.

| Field | Meaning |
|---|---|
| `customer_state` | Brazilian customer state |
| `total_revenue` | Total delivered-order revenue in BRL |
| `state_rank` | Rank by revenue |
| `revenue_share` | Share of total revenue |
| `concentration_tier` | Client-friendly grouping for high, medium, and long-tail states |

## customer_decile_summary.csv

Revenue concentration by customer decile. The dashboard export uses `customer_unique_id` so repeat buyers are treated as the same customer identity.

| Field | Meaning |
|---|---|
| `decile` | Customer spending decile, where 1 is highest-spending customers |
| `total_revenue` | Total revenue from the decile |
| `customer_count` | Number of customers in the decile |
| `revenue_share` | Share of total revenue from the decile |
| `cumulative_customer_share` | Cumulative share of customers through the decile |
| `cumulative_revenue_share` | Cumulative share of revenue through the decile |
| `segment_label` | Client-friendly decile label |

## customer_lorenz_curve.csv

Downsampled points for the Lorenz curve.

| Field | Meaning |
|---|---|
| `cumulative_customer_share` | Cumulative share of customers, sorted from lowest to highest revenue |
| `cumulative_revenue_share` | Cumulative share of revenue |

## payment_summary.csv

Revenue and order shares by payment structure.

| Field | Meaning |
|---|---|
| `payment_structure` | `One-time` or `Installment` |
| `total_revenue` | Total delivered-order revenue in BRL |
| `order_count` | Number of delivered orders |
| `order_share` | Share of delivered orders |
| `revenue_share` | Share of delivered-order revenue |

## installment_distribution.csv

Revenue and order distribution by maximum installment count.

| Field | Meaning |
|---|---|
| `max_installments` | Maximum installment count observed for the order |
| `total_revenue` | Total delivered-order revenue in BRL |
| `order_count` | Number of delivered orders |
| `revenue_share` | Share of delivered-order revenue |
| `order_share` | Share of delivered orders |

## kpi_summary.csv

Executive KPI cards and client-facing explanations.

| Field | Meaning |
|---|---|
| `sort_order` | Display order |
| `risk_dimension` | Risk category |
| `kpi_name` | Technical metric name |
| `kpi_value` | Numeric KPI value |
| `display_value` | Formatted KPI value for dashboard cards |
| `risk_level` | Client-friendly risk level |
| `client_explanation` | Plain-English interpretation |
| `pattern_observation` | Descriptive observation about the underlying data pattern that an analyst would surface for further discussion |

## action_plan.csv

Client-facing action plan for the final dashboard tab. Note: the content describes *patterns observed in the data* and *metrics to track*; specific intervention decisions are left to PMs and business owners.

| Field | Meaning |
|---|---|
| `priority` | Display order |
| `action_area` | Business area where the pattern surfaces |
| `business_question` | Question the dashboard helps answer |
| `dashboard_view` | Relevant dashboard section |
| `pattern_observation` | Descriptive observation about the data pattern |
| `tracking_metric` | Metric (with baseline value) suitable for ongoing monitoring |
