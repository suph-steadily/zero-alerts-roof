-- RUN 2026-09-23. Completed SELECTs; returned rows per statement: 394, 1.
-- Purpose: Monthly quote/home score coverage, invalid years and version mix.
-- Claim IDs: S4 S5 S13 S15 S17 S22 R2 A16 A23
-- Expected if the first read is right: May-Aug 101+ issued homes have 28 unscored of 5481 historically; quote-any coverage differs. BIND-RATE grain: 53804/47435=1.134.
-- Output is aggregate only. Live current rows cannot restore an earlier warehouse snapshot.

WITH base AS (
 SELECT *, toStartOfMonth(pol_created_timestamp) AS creation_month,
        multiIf(pol_prop_year_built<=1700,'unknown',2026-pol_prop_year_built>=101,'101+',2026-pol_prop_year_built>=91,'91-100',2026-pol_prop_year_built>=80,'80-90','under80') AS age_band
 FROM dbt.ipod_standard_mga_raw_policy_info
 WHERE quote_type='NewBusiness' AND pol_created_timestamp>=toDateTime('2026-01-01')
 AND pol_created_timestamp<toDateTime('2026-08-16')
)
SELECT creation_month, age_band, quote_status, pol_prop_steadily_roof_condition_score_model_version AS model_version,
       count() AS dwelling_rows, uniqExact(tuple(quote_id,dwelling_id)) AS quote_homes,
       uniqExact(quote_id) AS quotes,
       countIf(pol_prop_steadily_roof_condition_score_condition_score IS NOT NULL) AS scored_rows,
       uniqExactIf(quote_id,pol_prop_steadily_roof_condition_score_condition_score IS NOT NULL) AS quotes_any_scored,
       countIf(pol_prop_steadily_roof_condition_score_condition_score IS NULL) AS unscored_rows
FROM base GROUP BY creation_month, age_band, quote_status, model_version
ORDER BY creation_month, age_band, quote_status, model_version;

SELECT count() AS rows_, uniqExact(tuple(quote_id,dwelling_id)) AS quote_homes,
       uniqExact(quote_id) AS quotes, 1.0*quote_homes/nullIf(quotes,0) AS homes_per_quote
FROM dbt.ipod_standard_mga_raw_policy_info
WHERE quote_type='NewBusiness' AND pol_created_timestamp>=toDateTime('2026-04-01')
AND pol_created_timestamp<toDateTime('2026-08-12')
AND pol_prop_year_built>1700 AND 2026-pol_prop_year_built>=101;
-- Do not sum per-model quote counts: a quote can have dwellings on different versions.
-- The query groups creation month, not issued month. Neither reconstructs the score's arrival.
