# Marketplace Revenue Risk Analysis
library(DBI)
library(RPostgres)
library(ggplot2)
library(dplyr)

con <- dbConnect(
  RPostgres::Postgres(),
  dbname = "leowan34",
  host = "localhost",
  port = 5332,
  user = "leowan34",
  password = Sys.getenv("PG_PASSWORD")
)


monthly <- dbReadTable(con, "monthly_revenue")
customer <- dbReadTable(con, "customer_revenue_decile")
payment <- dbReadTable(con, "order_payment_structure")


# str(monthly)
# str(customer)
# str(payment)



# Revenue Time Stability
# Objective: Evaluate volatility of monthly revenue

sd_rev <- sd(monthly$monthly_revenue)
mean_rev <- mean(monthly$monthly_revenue)
cv_rev <- sd_rev / mean_rev

# The coefficient of variation (CV) of monthly revenue is 0.42,
# indicating moderate revenue volatility over the observed period.
sd_rev
cv_rev

monthly <- monthly %>%
  arrange(month) %>%
  mutate(
    mom_growth = (monthly_revenue - lag(monthly_revenue)) /
      lag(monthly_revenue)
  )

# 0.32 of month growth shows a significant variability in growth
sd(monthly$mom_growth, na.rm = TRUE)


# Revenue Trend
ggplot(monthly, aes(x = month, y = monthly_revenue)) +
  geom_line(linewidth = 1.2, color = "#2C3E50") +
  geom_point(size = 2, color = "#1ABC9C") +
  labs(
    title = "Monthly Revenue Trend",
    x = "Month",
    y = "Revenue"
  ) +
  theme_minimal()


# MoM Growth
ggplot(monthly, aes(x = month, y = mom_growth)) +
  geom_col(fill = "#3498DB") +
  geom_hline(yintercept = 0, linetype = "dashed") +
  labs(
    title = "Month-over-Month Revenue Growth",
    x = "Month",
    y = "MoM Growth Rate"
  ) +
  theme_minimal()



# Geographic Concentration
# Objective: Check whether income is overly dependent on a few specific regions

state <- dbReadTable(con, "state_revenue")

state <- state %>%
  arrange(desc(total_revenue)) %>%
  mutate(
    revenue_share = total_revenue / sum(total_revenue)
  )
head(state)


# showing a moderate geographic concentration risk. (40–70%)
ggplot(state, aes(x = reorder(customer_state, revenue_share),
                  y = revenue_share)) +
  geom_col(fill = "#3498DB") +
  coord_flip() +
  labs(
    title = "Revenue Share by State",
    x = "State",
    y = "Revenue Share"
  ) +
  theme_minimal()


hhi <- sum(state$revenue_share^2)
hhi



# Customer Concentration
customer <- dbReadTable(con, "customer_revenue_decile")
head(customer)

decile_summary <- customer %>%
  group_by(decile) %>%
  summarise(
    customer_count = n(),
    total_revenue = sum(total_revenue)
  ) %>%
  arrange(decile) %>%
  mutate(
    revenue_share = total_revenue / sum(total_revenue)
  )

decile_summary

# Customer Revenue Distribution
ggplot(decile_summary, aes(x = factor(decile), y = revenue_share)) +
  geom_col(fill = "#9B59B6") +
  labs(
    title = "Revenue Share by Customer Decile",
    x = "Customer Decile",
    y = "Revenue share"
  ) +
  theme_minimal()

# Lorenz curve

customer_sort <- customer %>%
  arrange(total_revenue) %>%
  mutate(
    cum_customer = row_number() / n(),
    cum_revenue = cumsum(total_revenue) / sum(total_revenue)
  )
head(customer_sort)


ggplot(customer_sort, aes(x = cum_customer, y = cum_revenue)) +
  geom_line(color = "#E67E22", linewidth = 1.2) +
  geom_abline(linetype = "dashed") +
  labs(
    title = "Lorenz Curve of Customer Revenue Distribution",
    x = "Cumulative Share of Customers",
    y = "Cumulative Share of Revenue"
  ) +
  theme_minimal()

# Gini coefficient
library(ineq)
gini <- ineq(customer$total_revenue, type = "Gini")
gini

# Liquidity Risk
payment <- dbReadTable(con, "order_payment_structure")
head(payment)

payment_summary <- payment %>%
  group_by(payment_type) %>%
  summarise(
    order_count = n(),
    total_revenue = sum(order_total)
  ) %>%
  mutate(
    order_share = order_count / sum(order_count),
    revenue_share = total_revenue / sum(total_revenue)
  )

payment_summary

ggplot(payment_summary, aes(x = payment_type, y = revenue_share)) +
  geom_col(fill = "#1ABC9C") +
  labs(
    title = "Revenue Share by Payment Type",
    x = "Payment type",
    y = "Revenue Share"
  )

weighted_installment <- sum(payment$max_installments * payment$order_total) /
  sum(payment$order_total)

weighted_installment
