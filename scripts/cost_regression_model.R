install.packages("dotenv")
library(DBI)
library(RPostgres)
library(tidyverse)
library(broom)
library(dotenv)

load_dot_env(file = "../.env")

con <- dbConnect(RPostgres::Postgres(),
                  dbname = Sys.getenv("DB_NAME"),
                  host = Sys.getenv("DB_HOST"),
                  port = as.integer(Sys.getenv("DB_PORT")),
                  user = Sys.getenv("DB_USER"),
                  password = Sys.getenv("DB_PASSWORD"))

                  
df <- dbGetQuery(con, "
  SELECT clm_pmt_amt, bene_birth_dt, sp_diabetes, sp_chf, sp_cncr, sp_copd, claim_year
  FROM claims_with_beneficiary
")

df <- df %>%
  mutate(
    age = claim_year - lubridate::year(as.Date(bene_birth_dt)),
    sp_diabetes = ifelse(sp_diabetes == 1, 1, 0),
    sp_chf = ifelse(sp_chf == 1, 1, 0),
    sp_cncr = ifelse(sp_cncr == 1, 1, 0),
    sp_copd = ifelse(sp_copd == 1, 1, 0)
  )

model <- lm(clm_pmt_amt ~ age + sp_diabetes + sp_chf + sp_cncr + sp_copd, data = df)
summary(model)
tidy(model)
glance(model)

dbDisconnect(con)