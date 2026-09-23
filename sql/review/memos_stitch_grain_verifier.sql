-- RUN 2026-09-23, all three SELECTs completed, one aggregate row each. Metabase db 235.
-- Purpose: Reproduce missing verifier grain, same-row flag/decision and mixed-age checks.
-- Claims: B1 B10 B16 O13 N12 N15
-- Expected if the memo is right: B: 53804 rows/47435 quotes; O: 3414/3415 signatures same row; N: 144/2788 mixed-age hand policies.
-- Reproduces memo age and current-row definitions, not a corrected event-sourced population.
-- These are separate aggregate checks. No raw identifiers are returned.
SELECT count() AS rows,uniqExact((quote_id,dwelling_id)) AS quote_dwellings,
 uniqExact(quote_id) AS quotes,uniqExactIf(quote_id,quote_status='Issued') AS issued_quotes
FROM dbt.ipod_standard_mga_raw_policy_info WHERE quote_type='NewBusiness'
AND pol_created_timestamp>=toDateTime('2026-04-01 00:00:00')
AND pol_created_timestamp<toDateTime('2026-08-12 00:00:00')
AND pol_prop_year_built>1700 AND 2026-pol_prop_year_built>=101;

WITH q AS (
 SELECT quote_id,max(pol_ff_automated_roof_exclusion='yes') AS flag_yes,max(pol_prop_steadily_roof_condition_score_decision='exclude') AS exclude,
 max(pol_ff_automated_roof_exclusion='yes' AND pol_prop_steadily_roof_condition_score_decision='exclude') AS same_row
 FROM dbt.ipod_standard_mga_raw_policy_info WHERE quote_type='NewBusiness'
 AND pol_created_timestamp>=toDateTime('2026-04-01 00:00:00')
 AND pol_created_timestamp<toDateTime('2026-08-01 00:00:00') GROUP BY quote_id
) SELECT countIf(flag_yes AND exclude) AS stitched_quotes,
 countIf(flag_yes AND exclude AND same_row) AS same_row_quotes FROM q;

WITH p AS (
 SELECT policy_id,uniqExact(quote_id) AS issued_nb_quotes,
 max(toYear(pol_created_timestamp)-pol_prop_year_built) AS age,
 max(prop_cov_roof_surfacing_exclusion='selected') AS rse,
 max(prop_cov_roof_surfacing_exclusion='selected' AND toYear(pol_created_timestamp)-pol_prop_year_built>=101) AS rse101,
 max(prop_cov_roof_surfacing_exclusion='selected' AND pol_ff_automated_roof_exclusion='yes' AND pol_prop_steadily_roof_condition_score_decision='exclude') AS auto
 FROM dbt.ipod_standard_mga_raw_policy_info WHERE quote_type='NewBusiness' AND quote_status='Issued'
 AND pol_created_timestamp>=toDateTime('2024-01-01 00:00:00')
 AND pol_created_timestamp<toDateTime('2026-07-01 00:00:00') AND pol_prop_year_built>1700
 GROUP BY policy_id
) SELECT count() AS policies, sum(issued_nb_quotes) AS issued_nb_quote_total,
 countIf(issued_nb_quotes>1) AS multiple_issued_nb_policies,
 countIf(age>=101 AND rse AND NOT auto) AS hand101_policies,
 countIf(age>=101 AND rse AND NOT auto AND NOT rse101) AS hand101_exclusion_only_younger
FROM p;
