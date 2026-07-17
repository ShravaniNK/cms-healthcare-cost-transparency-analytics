install.packages("dotenv")
library(DBI)
library(RPostgres)
library(tidyverse)
library(car)     # for Levene's test
library(broom)
library(dotenv)

load_dot_env(file = "../.env")

con <- dbConnect(RPostgres::Postgres(),
                  dbname = Sys.getenv("DB_NAME"),
                  host = Sys.getenv("DB_HOST"),
                  port = as.integer(Sys.getenv("DB_PORT")),
                  user = Sys.getenv("DB_USER"),
                  password = Sys.getenv("DB_PASSWORD"))


# Pull claim-level cost with diabetes flag
df <- dbGetQuery(con, "
  SELECT clm_pmt_amt, sp_diabetes, sp_chf, sp_cncr
  FROM claims_with_beneficiary
")

df$sp_diabetes <- factor(df$sp_diabetes, labels = c('Has Condition', 'No Condition'))

# Check variance homogeneity before ANOVA
leveneTest(clm_pmt_amt ~ sp_diabetes, data = df)

# T-test: cost difference between diabetic vs non-diabetic claims
t_test_result <- t.test(clm_pmt_amt ~ sp_diabetes, data = df)
print(t_test_result)

# ANOVA across multiple condition groups (example: diabetes x CHF combined groups)
df$condition_group <- interaction(df$sp_diabetes, df$sp_chf)
anova_result <- aov(clm_pmt_amt ~ condition_group, data = df)
summary(anova_result)

# Tidy output for reporting
tidy(t_test_result)
tidy(anova_result)

dbDisconnect(con)