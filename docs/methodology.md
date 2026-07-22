# Methodology & Data Limitations

## Data Source

This project uses the CMS Data Entrepreneurs' Synthetic Public Use File (DE-SynPUF), Sample 1, covering 2008–2010. It includes Beneficiary Summary files for each year plus Inpatient and Outpatient Claims files, linked via the synthetic beneficiary identifier `DESYNPUF_ID`.

## Why Synthetic Data

DE-SynPUF was built by CMS specifically so that analysts, researchers, and developers can practice working with realistic Medicare claims structures without accessing real, protected beneficiary data. CMS states explicitly in its own documentation that the disclosure-protection methods used to synthesize this data (hot-decking, variable coarsening, date perturbation) reduce much of the true statistical interdependence between variables. As a result:

- **This project's findings should not be interpreted as real conclusions about Medicare beneficiaries or actual healthcare spending patterns.**
- The value of this project lies in demonstrating a complete, methodologically sound claims-analytics pipeline which includes cleaning, relational modeling, cost aggregation, visualization, and statistical inference using data structured identically to real CMS claims data.

## Data Cleaning Decisions

**Date parsing**: Beneficiary birth/death dates and claim service dates were parsed from CMS's `YYYYMMDD` integer format into standard date types. `BENE_DEATH_DT` is null for the majority of beneficiaries, which is expected (most beneficiaries in the sample are alive).

**Chronic condition flags**: Columns like `SP_DIABETES`, `SP_CHF`, `SP_CNCR`, etc. are coded `1` (has condition) / `2` (does not) per the CMS codebook. `BENE_ESRD_IND` is coded differently (`'Y'` / `'0'`) and was handled separately during the SQL load step to avoid a type-casting error.

**Claims-to-beneficiary join**: Claims were joined to beneficiary records on `DESYNPUF_ID` and matching year. Approximately 1.4% of claims (12,040 of 857,563) did not have a matching beneficiary-year record after the join. This is consistent with known gaps in DE-SynPUF's synthetic linkage process and was judged small enough not to materially affect the aggregate cost analysis; these unmatched claims were retained in the full dataset but will show null demographic/condition fields.

**Negative and zero-dollar claims**: The claims data includes a small number of negative claim payment amounts (minimum observed: -$8,000) and roughly 4% of claims (34,886 of 857,563) with a payment amount of $0 or less. Negative values most likely represent claim adjustments or reversals rather than data errors. These were excluded from the claim-cost distribution visualization specifically (to avoid breaking log-scale rendering) but were retained in the full dataset and in all SQL aggregation totals, since excluding them entirely would understate the effect of billing adjustments that occur in real claims processing.

## Statistical Inference Notes

**Chronic condition cost comparisons (t-tests/ANOVA)**: Given the scale of the dataset (hundreds of thousands of claims), statistical significance in a t-test or ANOVA is easy to achieve even for small, practically negligible differences in mean cost. Results should be interpreted alongside effect size, not p-values alone.

**Year-over-year growth confidence intervals**: The dataset spans only three years (2008–2010), producing only two year-over-year growth observations per claim type. This is too small a sample to support a statistically robust confidence interval on growth rate; the R script produces this output for methodological completeness, but the resulting interval should be read as illustrative rather than a reliable estimate.

**Cost regression model**: A linear model of claim cost on beneficiary age and chronic condition flags was fit to demonstrate the approach. Given DE-SynPUF's synthetic disclosure-protection methods intentionally reduce true variable interdependence, the model's R² is expected to be low and should not be read as evidence of weak real-world relationships between age, chronic conditions, and healthcare cost. It is only as a demonstration of the modeling approach on this specific dataset.

## Summary

Every limitation noted above reflects a deliberate, documented choice rather than an unnoticed gap. In a production setting, working with real CMS claims data for an actual Cost Transparency Board, the same pipeline structure would apply, with the caveats above replaced by genuine population-level statistical validity checks.
