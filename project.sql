/*
Project: Marketplace Revenue Risk & Financial Stability Analysis
Company: Olist (Brazilian E-commerce Platform)

Objective:
Construct financial risk indicators using transaction-level data.
*/


-- ============================================
-- Module 0: Financial Orders Fact Table
-- Objective: Construct order-level financial dataset
-- ============================================
CREATE OR REPLACE VIEW financial_orders AS
SELECT
    o.order_id,
    o.customer_id,
    c.customer_state,
    o.order_purchase_timestamp,
    ROUND(SUM(p.payment_value)::numeric, 2) AS order_total,
    MAX(p.payment_installments)::int AS max_installments,
    COUNT(p.payment_sequential) AS payment_count
FROM olist_orders_dataset o
JOIN olist_customers_dataset c
    ON o.customer_id = c.customer_id
JOIN olist_order_payments_dataset p
    ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY
    o.order_id,
    o.customer_id,
    c.customer_state,
    o.order_purchase_timestamp;


SELECT *
FROM financial_orders
LIMIT 50;



-- ============================================
-- Module 1: Geographic Revenue Distribution
-- Prepare state-level revenue concentration dataset
-- ============================================
CREATE OR REPLACE VIEW state_revenue AS
SELECT
    customer_state,
    SUM(order_total) AS total_revenue
FROM financial_orders
GROUP BY customer_state;

SELECT *
FROM state_revenue
LIMIT 50;

-- Calculates revenue distribution by state
WITH state_revenue AS (
    SELECT
        customer_state,
        SUM(order_total) AS total_revenue
    FROM financial_orders
    GROUP BY customer_state
),
state_ranked AS (
    SELECT
        customer_state,
        total_revenue,
        total_revenue /
        SUM(total_revenue) OVER () AS revenue_share,
        RANK() OVER (ORDER BY total_revenue DESC) AS rnk
    FROM state_revenue
)
SELECT
    SUM(revenue_share) AS top3_share
FROM state_ranked
WHERE rnk <= 3;



-- ======================================================
-- Module 2: Customer Revenue Segmentation
-- Objective: Prepare customer-level revenue dataset for concentration and distribution analysis in R
-- ======================================================


-- Customer-level revenue aggregation
CREATE OR REPLACE VIEW customer_revenue AS
SELECT
    customer_id,
    SUM(order_total) AS total_revenue
FROM financial_orders
GROUP BY customer_id;



-- Customer decile segmentation (NTILE-based)
CREATE OR REPLACE VIEW customer_revenue_decile AS
SELECT
    customer_id,
    total_revenue,
    NTILE(10) OVER (ORDER BY total_revenue DESC) AS decile
FROM customer_revenue;



-- quick preview
SELECT *
FROM customer_revenue_decile
ORDER BY decile, total_revenue DESC
LIMIT 50;



-- ======================================================
-- Module 3: Installment & Liquidity Structure
-- Prepare payment structure dataset for liquidity exposure analysis in R
-- ======================================================

CREATE OR REPLACE VIEW order_payment_structure AS
SELECT
    order_id,
    order_total,
    max_installments,
    CASE
        WHEN max_installments = 1 THEN 'One-time'
        ELSE 'Installment'
    END AS payment_type
FROM financial_orders
WHERE max_installments >= 1;

SELECT *
FROM order_payment_structure
LIMIT 50;

-- ======================================================
-- Module 4: Revenue Time-Series Preparation
-- Construct monthly revenue dataset for statistical modeling in R
-- ======================================================

CREATE OR REPLACE VIEW monthly_revenue AS
SELECT
    DATE_TRUNC('month', order_purchase_timestamp::timestamp) AS month,
    SUM(order_total) AS monthly_revenue
FROM financial_orders
WHERE order_purchase_timestamp::timestamp >= '2017-01-01'
GROUP BY month
ORDER BY month;

SELECT * FROM monthly_revenue;