-- 1. Total cost by service category (claim type) and year
SELECT
    claim_type,
    claim_year,
    SUM(clm_pmt_amt) AS total_cost,
    COUNT(*) AS claim_count,
    ROUND(AVG(clm_pmt_amt), 2) AS avg_cost_per_claim
FROM claims_with_beneficiary
GROUP BY claim_type, claim_year
ORDER BY claim_type, claim_year;

-- 2. Year-over-year cost growth by claim type
WITH yearly_cost AS (
    SELECT claim_type, claim_year, SUM(clm_pmt_amt) AS total_cost
    FROM claims_with_beneficiary
    GROUP BY claim_type, claim_year
)
SELECT
    claim_type,
    claim_year,
    total_cost,
    LAG(total_cost) OVER (PARTITION BY claim_type ORDER BY claim_year) AS prior_year_cost,
    ROUND(
        100.0 * (total_cost - LAG(total_cost) OVER (PARTITION BY claim_type ORDER BY claim_year))
        / NULLIF(LAG(total_cost) OVER (PARTITION BY claim_type ORDER BY claim_year), 0), 2
    ) AS yoy_growth_pct
FROM yearly_cost
ORDER BY claim_type, claim_year;

-- 3. Cost by chronic condition flag (example: diabetes; repeat pattern for others)
SELECT
    sp_diabetes,
    COUNT(DISTINCT desynpuf_id) AS beneficiary_count,
    SUM(clm_pmt_amt) AS total_cost,
    ROUND(AVG(clm_pmt_amt), 2) AS avg_cost_per_claim
FROM claims_with_beneficiary
GROUP BY sp_diabetes;

-- 3b. All chronic conditions in one summary (cost per condition group, using UNION)
SELECT 'CHF' AS condition, sp_chf AS flag, SUM(clm_pmt_amt) AS total_cost FROM claims_with_beneficiary GROUP BY sp_chf
UNION ALL
SELECT 'Diabetes', sp_diabetes, SUM(clm_pmt_amt) FROM claims_with_beneficiary GROUP BY sp_diabetes
UNION ALL
SELECT 'Cancer', sp_cncr, SUM(clm_pmt_amt) FROM claims_with_beneficiary GROUP BY sp_cncr
UNION ALL
SELECT 'COPD', sp_copd, SUM(clm_pmt_amt) FROM claims_with_beneficiary GROUP BY sp_copd
ORDER BY condition, flag;

-- 4. Top 10 highest-cost individual claims
SELECT desynpuf_id, clm_id, claim_type, claim_year, clm_pmt_amt, prvdr_num
FROM claims_with_beneficiary
ORDER BY clm_pmt_amt DESC
LIMIT 10;

-- 4b. Top 10 highest-cost providers (aggregate, more useful for policy analysis)
SELECT prvdr_num, SUM(clm_pmt_amt) AS total_cost, COUNT(*) AS claim_count
FROM claims_with_beneficiary
GROUP BY prvdr_num
ORDER BY total_cost DESC
LIMIT 10;