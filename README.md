# Marketplace Revenue Risk & Financial Stability Analysis

## Overview

This project analyzes the financial stability of marketplace revenue using real-world e-commerce data. 

The analysis focuses on four key dimensions: revenue volatility, geographic concentration, customer concentration, and liquidity risk.


## Data Context

The analysis is based on the Brazilian E-Commerce Public Dataset by Olist, which contains approximately 100,000 orders from 2016 to 2018.

This project focuses on three core tables:
- Orders data (order-level information)
- Customer data (customer identifiers and location)
- Payment data (payment types and installment structure)

These datasets are combined to analyze revenue from multiple perspectives, including time, geography, customer segments, and payment behavior.

The dataset reflects real-world e-commerce operations, making it suitable for evaluating financial stability and business risk.


## Key Findings

- Revenue shows a moderate volatility, showing instability in short-term.
- Revenue is geographically concentrated, with Sao Paulo contributing approximately 37% of total revenue.
- Customer concentration is significant, with the top decile contributing about 38% of total revenue and a Gini coefficient of around 0.47.
- Payment structure indicates liquidity risk, with installment payments dominating revenue and an average installment count of approximately 4.1.

Overall, the business faces a moderate financial risk driven by revenue concentration and cash flow timing constraints.


## Methodology

- SQL was used to extract and prepare data from relational tables
- R was used for data processing, analysis, and visualization
- Key metrics include CV, HHI, Gini coefficient, and weighted installment count


## Project Structure

- Analysis.Rmd: Main analysis report
- Analysis.html: Rendered report
- Data/: Raw datasets
- R/: R scripts
- SQL/: SQL queries


## Report

View full report: https://lilwan345.github.io/Marketplace-Revenue-Risk-Financial-Stability-Analysis/
