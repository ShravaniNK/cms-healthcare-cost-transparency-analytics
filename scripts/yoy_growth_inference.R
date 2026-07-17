install.packages("dotenv")
library(DBI)
library(RPostgres)
library(tidyverse)

library(dotenv)

load_dot_env(file = "../.env")

con <- dbConnect(RPostgres::Postgres(),
                  dbname = Sys.getenv("DB_NAME"),
                  host = Sys.getenv("DB_HOST"),
                  port = as.integer(Sys.getenv("DB_PORT")),
                  user = Sys.getenv("DB_USER"),
                  password = Sys.getenv("DB_PASSWORD"))



yearly <- dbGetQuery(con, "
  SELECT claim_type, claim_year, SUM(clm_pmt_amt) AS total_cost
  FROM claims_with_beneficiary
  GROUP BY claim_type, claim_year
  ORDER BY claim_type, claim_year
")

# Calculate YoY growth rate
yearly <- yearly %>%
  group_by(claim_type) %>%
  arrange(claim_year) %>%
  mutate(growth_rate = (total_cost - lag(total_cost)) / lag(total_cost)) %>%
  filter(!is.na(growth_rate))

# Confidence interval on mean growth rate (across claim types, treating as a sample)
growth_ci <- t.test(yearly$growth_rate)
print(growth_ci)

# Per claim-type CI (if enough data points; note small n here — 2 years of growth per type is limited)
yearly %>%
  group_by(claim_type) %>%
  summarise(
    mean_growth = mean(growth_rate),
    n = n()
  )

dbDisconnect(con)