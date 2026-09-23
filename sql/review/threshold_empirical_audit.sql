-- RUN 2026-09-23. 9 aggregate rows. See review/threshold_empirical_runs.json.
-- Purpose: validate current-row quote-home grain and candidate cohort before a full integer sweep.
-- Claims: user follow-up on choosing the bar; A14 A17 A20 A39 A40.
-- Expected: unique quote-home rows, integer scores, and unchanged historical v1.2.0 counts.
-- SELECT only; aggregate output only. Current rows are not decision-time history.
WITH base AS (
 SELECT policy_id,quote_id,dwelling_id,quote_status,quote_issued_timestamp,
   pol_created_timestamp AS created_at,pol_prop_year_built AS year_built,
   pol_prop_state AS state,
   pol_prop_steadily_roof_condition_score_model_version AS model_version,
   pol_prop_steadily_roof_condition_score_condition_score AS score,
   prop_cov_roof_surfacing_exclusion AS exclusion,
   pol_ff_automated_roof_exclusion AS flag,
   pol_prop_steadily_roof_condition_score_decision AS decision
 FROM dbt.ipod_standard_mga_raw_policy_info
 WHERE quote_type='NewBusiness'
   AND pol_created_timestamp>=toDateTime('2026-05-01','America/Chicago')
   AND pol_created_timestamp<toDateTime('2026-09-01','America/Chicago')
   AND pol_prop_year_built>1700
   AND toYear(toTimeZone(pol_created_timestamp,'America/Chicago'))-pol_prop_year_built>=101
), expanded AS (
 SELECT *,arrayJoin(['historical_May01_Aug15','primary_Jul30_Aug31']) AS cohort
 FROM base
 WHERE (cohort='historical_May01_Aug15' AND created_at<toDateTime('2026-08-16','America/Chicago'))
    OR (cohort='primary_Jul30_Aug31' AND created_at>=toDateTime('2026-07-30','America/Chicago') AND state NOT IN ('CO','RI','WV'))
)
SELECT cohort,model_version,count() AS raw_rows,
 uniqExact(tuple(quote_id,dwelling_id)) AS quote_home_keys,
 uniqExact(quote_id) AS quotes,uniqExact(policy_id) AS policies,
 countIf(score IS NULL) AS unscored,
 countIf(score IS NOT NULL AND score!=round(score)) AS noninteger_scores,
 countIf(score<0 OR score>100) AS scores_outside_0_100,
 countIf((quote_status='Issued')!=(quote_issued_timestamp IS NOT NULL)) AS issue_status_disagreements,
 countIf(exclusion='selected' AND flag='yes' AND decision='exclude') AS auto_signature_homes,
 countIf(exclusion='selected' AND NOT(flag='yes' AND decision='exclude')) AS hand_signature_homes,
 countIf(quote_status='Issued' AND quote_issued_timestamp<toDateTime('2026-09-23','America/Chicago')) AS issued_by_cutoff_homes
FROM expanded GROUP BY cohort,model_version ORDER BY cohort,model_version;
