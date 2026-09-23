-- RUN 2026-09-23. Completed SELECTs; returned rows per statement: 1.
-- Purpose: Check sql/01 grain, status/timestamp equivalence, invalid year-built, and score integer assumption.
-- Claim IDs: S6 S16 S21 Q1 A17 A20
-- Expected if the first read is right: No duplicate issued policy/dwelling keys; no status/issue disagreement; no noninteger scores. The 25 invalid-year quotes have no precise original probe window.
-- Output is aggregate only. Live current rows cannot restore an earlier warehouse snapshot.

WITH base AS (
 SELECT * FROM dbt.ipod_standard_mga_raw_policy_info
 WHERE quote_type='NewBusiness'
   AND pol_created_timestamp >= toDateTime('2026-04-01 00:00:00')
   AND pol_created_timestamp < toDateTime('2026-08-16 00:00:00')
)
SELECT count() AS nb_rows, uniqExact(quote_id) AS nb_quotes,
       countIf((quote_status='Issued') != (quote_issued_timestamp IS NOT NULL)) AS status_issue_mismatches,
       uniqExactIf(quote_id, pol_prop_year_built<=1700) AS invalid_year_quotes,
       countIf(pol_prop_steadily_roof_condition_score_condition_score IS NOT NULL AND pol_prop_steadily_roof_condition_score_condition_score != round(pol_prop_steadily_roof_condition_score_condition_score)) AS noninteger_score_rows,
       countIf(quote_status='Issued' AND pol_prop_year_built>1700 AND 2026-pol_prop_year_built>=80) AS issued_80plus_rows,
       uniqExactIf(tuple(policy_id,dwelling_id), quote_status='Issued' AND pol_prop_year_built>1700 AND 2026-pol_prop_year_built>=80) AS issued_80plus_keys,
       countIf(quote_status='Issued' AND pol_prop_year_built>1700 AND 2026-pol_prop_year_built>=101 AND pol_created_timestamp>=toDateTime('2026-05-01')) AS issued_101plus_rows,
       uniqExactIf(tuple(policy_id,dwelling_id), quote_status='Issued' AND pol_prop_year_built>1700 AND 2026-pol_prop_year_built>=101 AND pol_created_timestamp>=toDateTime('2026-05-01')) AS issued_101plus_keys
FROM base;
-- The original sql/01 is open-ended. This pins its window for comparison; repeat with
-- a declared run cutoff if testing its actual open-ended output. Never export the keys.
