#
# Export Tableau-ready datasets for the marketplace revenue risk dashboard.
# The script uses only the raw Olist CSV files in this repository, so the
# Tableau workflow does not depend on a local PostgreSQL database.
#

options(stringsAsFactors = FALSE)

output_dir <- "tableau_data"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

orders <- read.csv("olist_orders_dataset.csv")
customers <- read.csv("olist_customers_dataset.csv")
payments <- read.csv("olist_order_payments_dataset.csv")

orders$order_purchase_timestamp <- as.POSIXct(
  orders$order_purchase_timestamp,
  format = "%Y-%m-%d %H:%M:%S",
  tz = "UTC"
)

delivered_orders <- orders[orders$order_status == "delivered", ]

payment_order_totals <- aggregate(
  payment_value ~ order_id,
  payments,
  sum
)
names(payment_order_totals)[names(payment_order_totals) == "payment_value"] <- "order_total"

payment_installments <- aggregate(
  payment_installments ~ order_id,
  payments,
  max
)
names(payment_installments)[names(payment_installments) == "payment_installments"] <- "max_installments"

payment_counts <- aggregate(
  payment_sequential ~ order_id,
  payments,
  length
)
names(payment_counts)[names(payment_counts) == "payment_sequential"] <- "payment_count"

financial_orders <- merge(
  delivered_orders[, c("order_id", "customer_id", "order_purchase_timestamp")],
  customers[, c("customer_id", "customer_unique_id", "customer_state")],
  by = "customer_id",
  all.x = TRUE
)

financial_orders <- merge(financial_orders, payment_order_totals, by = "order_id")
financial_orders <- merge(financial_orders, payment_installments, by = "order_id")
financial_orders <- merge(financial_orders, payment_counts, by = "order_id")
financial_orders$payment_structure <- ifelse(
  financial_orders$max_installments == 1,
  "One-time",
  "Installment"
)

financial_orders$order_month <- as.Date(
  paste0(format(financial_orders$order_purchase_timestamp, "%Y-%m"), "-01")
)

financial_orders_2017_plus <- financial_orders[
  financial_orders$order_purchase_timestamp >= as.POSIXct("2017-01-01", tz = "UTC"),
]

monthly_revenue <- aggregate(
  order_total ~ order_month,
  financial_orders_2017_plus,
  sum
)
names(monthly_revenue) <- c("month", "monthly_revenue")
monthly_revenue <- monthly_revenue[order(monthly_revenue$month), ]
monthly_revenue$mom_growth <- c(
  NA,
  diff(monthly_revenue$monthly_revenue) /
    head(monthly_revenue$monthly_revenue, -1)
)
monthly_revenue$growth_direction <- ifelse(
  is.na(monthly_revenue$mom_growth),
  "Baseline",
  ifelse(monthly_revenue$mom_growth >= 0, "Growth", "Decline")
)
monthly_revenue$volatility_signal <- ifelse(
  is.na(monthly_revenue$mom_growth),
  "Baseline month",
  ifelse(abs(monthly_revenue$mom_growth) >= 0.20, "High swing", "Normal movement")
)
monthly_revenue$monthly_revenue <- round(monthly_revenue$monthly_revenue, 2)
monthly_revenue$mom_growth <- round(monthly_revenue$mom_growth, 4)

state_revenue <- aggregate(
  order_total ~ customer_state,
  financial_orders,
  sum
)
names(state_revenue) <- c("customer_state", "total_revenue")
state_revenue <- state_revenue[order(-state_revenue$total_revenue), ]
state_revenue$state_rank <- seq_len(nrow(state_revenue))
state_revenue$revenue_share <- state_revenue$total_revenue / sum(state_revenue$total_revenue)
state_revenue$concentration_tier <- ifelse(
  state_revenue$state_rank <= 3,
  "Core revenue state",
  ifelse(state_revenue$state_rank <= 10, "Secondary state", "Long-tail state")
)
state_revenue$total_revenue <- round(state_revenue$total_revenue, 2)
state_revenue$revenue_share <- round(state_revenue$revenue_share, 4)

customer_revenue <- aggregate(
  order_total ~ customer_unique_id,
  financial_orders,
  sum
)
names(customer_revenue) <- c("customer_unique_id", "total_revenue")
customer_revenue <- customer_revenue[order(-customer_revenue$total_revenue), ]
customer_revenue$decile <- ceiling(seq_len(nrow(customer_revenue)) / nrow(customer_revenue) * 10)
customer_revenue$decile <- pmin(customer_revenue$decile, 10)

customer_decile_summary <- aggregate(
  total_revenue ~ decile,
  customer_revenue,
  sum
)
customer_decile_counts <- aggregate(
  customer_unique_id ~ decile,
  customer_revenue,
  length
)
names(customer_decile_counts)[2] <- "customer_count"
customer_decile_summary <- merge(customer_decile_summary, customer_decile_counts, by = "decile")
customer_decile_summary <- customer_decile_summary[order(customer_decile_summary$decile), ]
customer_decile_summary$revenue_share <- customer_decile_summary$total_revenue /
  sum(customer_decile_summary$total_revenue)
customer_decile_summary$cumulative_customer_share <- cumsum(customer_decile_summary$customer_count) /
  sum(customer_decile_summary$customer_count)
customer_decile_summary$cumulative_revenue_share <- cumsum(customer_decile_summary$total_revenue) /
  sum(customer_decile_summary$total_revenue)
customer_decile_summary$segment_label <- paste0(
  "Decile ",
  customer_decile_summary$decile,
  ifelse(customer_decile_summary$decile == 1, " - Highest spenders", "")
)
customer_decile_summary$total_revenue <- round(customer_decile_summary$total_revenue, 2)
customer_decile_summary$revenue_share <- round(customer_decile_summary$revenue_share, 4)
customer_decile_summary$cumulative_customer_share <- round(customer_decile_summary$cumulative_customer_share, 4)
customer_decile_summary$cumulative_revenue_share <- round(customer_decile_summary$cumulative_revenue_share, 4)

customer_lorenz <- customer_revenue[order(customer_revenue$total_revenue), ]
customer_lorenz$cumulative_customer_share <- seq_len(nrow(customer_lorenz)) / nrow(customer_lorenz)
customer_lorenz$cumulative_revenue_share <- cumsum(customer_lorenz$total_revenue) /
  sum(customer_lorenz$total_revenue)
customer_lorenz <- customer_lorenz[
  seq(1, nrow(customer_lorenz), length.out = min(1000, nrow(customer_lorenz))),
  c("cumulative_customer_share", "cumulative_revenue_share")
]
customer_lorenz$cumulative_customer_share <- round(customer_lorenz$cumulative_customer_share, 4)
customer_lorenz$cumulative_revenue_share <- round(customer_lorenz$cumulative_revenue_share, 4)

payment_summary <- aggregate(
  order_total ~ payment_structure,
  financial_orders,
  sum
)
names(payment_summary) <- c("payment_structure", "total_revenue")
payment_order_counts <- aggregate(
  order_id ~ payment_structure,
  financial_orders,
  length
)
names(payment_order_counts)[2] <- "order_count"
payment_summary <- merge(payment_summary, payment_order_counts, by = "payment_structure")
payment_summary$order_share <- payment_summary$order_count / sum(payment_summary$order_count)
payment_summary$revenue_share <- payment_summary$total_revenue / sum(payment_summary$total_revenue)
payment_summary$total_revenue <- round(payment_summary$total_revenue, 2)
payment_summary$order_share <- round(payment_summary$order_share, 4)
payment_summary$revenue_share <- round(payment_summary$revenue_share, 4)

installment_distribution <- aggregate(
  order_total ~ max_installments,
  financial_orders,
  sum
)
installment_counts <- aggregate(
  order_id ~ max_installments,
  financial_orders,
  length
)
names(installment_counts)[2] <- "order_count"
installment_distribution <- merge(
  installment_distribution,
  installment_counts,
  by = "max_installments"
)
names(installment_distribution)[2] <- "total_revenue"
installment_distribution$revenue_share <- installment_distribution$total_revenue /
  sum(installment_distribution$total_revenue)
installment_distribution$order_share <- installment_distribution$order_count /
  sum(installment_distribution$order_count)
installment_distribution$total_revenue <- round(installment_distribution$total_revenue, 2)
installment_distribution$revenue_share <- round(installment_distribution$revenue_share, 4)
installment_distribution$order_share <- round(installment_distribution$order_share, 4)

gini <- function(x) {
  x <- sort(x[!is.na(x)])
  n <- length(x)
  if (n == 0 || sum(x) == 0) {
    return(NA_real_)
  }
  (2 * sum(seq_len(n) * x) / (n * sum(x))) - ((n + 1) / n)
}

cv_rev <- sd(monthly_revenue$monthly_revenue, na.rm = TRUE) /
  mean(monthly_revenue$monthly_revenue, na.rm = TRUE)
hhi <- sum(state_revenue$revenue_share^2)
gini_customer <- gini(customer_revenue$total_revenue)
weighted_installment <- sum(
  financial_orders$max_installments * financial_orders$order_total
) / sum(financial_orders$order_total)
sp_share <- state_revenue$revenue_share[state_revenue$customer_state == "SP"]
top_decile_share <- customer_decile_summary$revenue_share[customer_decile_summary$decile == 1]
installment_share <- payment_summary$revenue_share[
  payment_summary$payment_structure == "Installment"
]

kpi_summary <- data.frame(
  sort_order = 1:4,
  risk_dimension = c(
    "Revenue Stability",
    "Geographic Concentration",
    "Customer Concentration",
    "Liquidity Risk"
  ),
  kpi_name = c(
    "Coefficient of Variation",
    "Herfindahl-Hirschman Index",
    "Gini Coefficient",
    "Revenue-weighted Avg. Installments"
  ),
  kpi_value = round(c(cv_rev, hhi, gini_customer, weighted_installment), 4),
  display_value = c(
    paste0(round(cv_rev, 2), " CV"),
    paste0(round(hhi, 2), " HHI"),
    paste0(round(gini_customer, 3), " Gini"),
    paste0(round(weighted_installment, 2), " installments")
  ),
  risk_level = c("Moderate", "Moderate", "Elevated", "Elevated"),
  client_explanation = c(
    "Monthly revenue is growing overall, but cash flow is still difficult to forecast month to month.",
    paste0("Revenue is meaningfully exposed to a few states; SP contributes ", round(sp_share * 100), "% of revenue."),
    paste0("The highest-spending customer decile contributes ", round(top_decile_share * 100), "% of revenue."),
    paste0("Installment-heavy orders contribute ", round(installment_share * 100), "% of revenue, delaying cash collection.")
  ),
  recommended_action = c(
    "Plan promotions around historically weak months and monitor large month-to-month swings.",
    "Expand seller and buyer acquisition in MG and PR to reduce dependency on SP.",
    "Protect high-value customers with loyalty benefits while broadening mid-tier repeat purchases.",
    "Introduce small incentives for one-time payment or lower-installment checkout choices."
  )
)

action_plan <- data.frame(
  priority = 1:4,
  action_area = c(
    "Revenue calendar",
    "Regional expansion",
    "Customer retention",
    "Cash collection"
  ),
  business_question = c(
    "Which months create the largest revenue planning risk?",
    "Which states should receive expansion investment?",
    "How dependent is revenue on the highest-value buyers?",
    "How much revenue is delayed by installment behavior?"
  ),
  dashboard_view = c(
    "Revenue Stability",
    "Geographic Concentration",
    "Customer Concentration",
    "Liquidity Risk"
  ),
  suggested_intervention = c(
    "Run mid-year and January retention campaigns to smooth demand shocks.",
    "Prioritize MG and PR seller recruitment and state-level campaigns.",
    "Launch tiered benefits for the top two customer deciles.",
    "Offer 3%-6% one-time payment incentives or free shipping for lower installment counts."
  ),
  success_metric = c(
    "Reduce revenue CV toward 0.30",
    "Reduce SP revenue share below 30%",
    "Increase repeat purchase rate in top 20% customers",
    "Reduce installment revenue share by 10 percentage points"
  )
)

write.csv(monthly_revenue, file.path(output_dir, "monthly_revenue.csv"), row.names = FALSE)
write.csv(state_revenue, file.path(output_dir, "state_revenue.csv"), row.names = FALSE)
write.csv(customer_decile_summary, file.path(output_dir, "customer_decile_summary.csv"), row.names = FALSE)
write.csv(customer_lorenz, file.path(output_dir, "customer_lorenz_curve.csv"), row.names = FALSE)
write.csv(payment_summary, file.path(output_dir, "payment_summary.csv"), row.names = FALSE)
write.csv(installment_distribution, file.path(output_dir, "installment_distribution.csv"), row.names = FALSE)
write.csv(kpi_summary, file.path(output_dir, "kpi_summary.csv"), row.names = FALSE)
write.csv(action_plan, file.path(output_dir, "action_plan.csv"), row.names = FALSE)

message("Tableau-ready datasets exported to ", normalizePath(output_dir))
