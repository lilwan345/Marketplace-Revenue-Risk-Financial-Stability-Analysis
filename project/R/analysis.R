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

sd_rev
cv_rev
# The coefficient of variation (CV) of monthly revenue is 0.42,
# indicating moderate revenue volatility over the observed period.

monthly <- monthly %>%
  arrange(month) %>%
  mutate(
    mom_growth = (monthly_revenue - lag(monthly_revenue)) /
      lag(monthly_revenue)
  )

sd(monthly$mom_growth, na.rm = TRUE)
# 0.32 of month growth shows a significant variability in growth



