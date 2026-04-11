# Marketplace Revenue Risk & Financial Stability Analysis

> Quantifying financial concentration and liquidity risk across 100,000+ e-commerce transactions using SQL and R.

📊 **[View Full Interactive Report](https://lilwan345.github.io/Marketplace-Revenue-Risk-Financial-Stability-Analysis/)**

---

## What This Project Does

This project builds a financial risk assessment framework on top of the Brazilian E-Commerce Public Dataset (Olist, 2016–2018). It identifies and quantifies four dimensions of revenue risk that matter to marketplace businesses:

| Risk Dimension | Key Metric | Finding |
|---|---|---|
| Revenue Stability | CV = 0.42 | Moderate volatility; unstable short-term growth |
| Geographic Concentration | HHI = 0.18 | São Paulo alone drives 37% of total revenue |
| Customer Concentration | Gini = 0.475 | Top 10% of customers contribute 38% of revenue |
| Liquidity Risk | Avg. Installments = 4.12 | Installment-heavy structure delays cash collection |

Bottom line: Based on findings, three targeted interventions are recommended: promotional calendar optimization to address revenue volatility, seller recruitment in MG and PR to reduce geographic concentration, and a loyalty program targeting the top customer decile to stabilize high-value revenue.
---

## Key Findings

- **Revenue is volatile short-term**: CV of 0.42 and highly uneven month-over-month growth signal unstable performance, despite an overall upward trend from 2017 to 2018.
- **São Paulo dominates geographically**: SP contributes ~37% of revenue, followed by RJ (~13%) and MG (~12%). HHI of 0.18 indicates moderate but meaningful concentration risk.
- **A small customer base drives most revenue**: The top decile alone accounts for 38% of revenue; the top 3 deciles contribute ~64%. The Lorenz curve and Gini coefficient (0.475) confirm high inequality.
- **Installment payments create liquidity lag**: Over 60% of revenue comes from installment orders, with an average of 4.12 installments per order — meaning cash is collected gradually, not upfront.

---

## Tools & Methods

**SQL (PostgreSQL)**
- Constructed modular views for financial orders, state revenue, customer deciles, and payment structure
- Applied window functions (NTILE, SUM OVER) for segmentation and ranking

**R (RMarkdown)**
- Calculated CV, HHI, Gini coefficient, and weighted installment count
- Visualized trends with ggplot2: line charts, bar charts, and Lorenz curve

---

## Project Structure

```
├── Analysis.Rmd          # Main analysis (R Markdown source)
├── Analysis.html         # Rendered interactive report
├── project.sql           # SQL views for data preparation
├── analysis.R            # Standalone R script
├── Data/
│   ├── olist_customers_dataset.csv
│   ├── olist_orders_dataset.csv
│   └── olist_order_payments_dataset.csv
```

---

## Data Source

[Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) — ~100,000 orders from 2016 to 2018, covering order details, customer locations, and payment structures.

> **Note:** This dataset reflects 2016–2018 Brazilian e-commerce operations. Findings are specific to this time period and market context.

---

## Author

**Liyuan Wan** · [GitHub](https://github.com/lilwan345)
