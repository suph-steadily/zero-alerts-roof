-- RUN 2026-09-23. Completed SELECTs; returned rows per statement: 16.
-- Purpose: Reproduce scored/unscored April snapshot policy conversion table on coherent issued states.
-- Claim IDs: RS24 RS25 RS27 R2
-- Expected if the first read is right: Legacy table sums to106 cancellations; 38 score83+ (37 newly covered); bar90 count21 here vs22 overlay needs investigation.
-- Output is aggregate only. Live current rows cannot restore an earlier warehouse snapshot.

WITH 
issued AS (
 SELECT policy_id,dwelling_id,
        argMax(tuple(pol_prop_steadily_roof_condition_score_condition_score,prop_cov_roof_surfacing_exclusion,pol_ff_automated_roof_exclusion,pol_prop_steadily_roof_condition_score_decision,pol_prop_steadily_roof_condition_score_model_version,pol_prop_state,pol_prop_year_built,quote_id,pol_created_timestamp,quote_issued_timestamp),quote_issued_timestamp) AS b,
        count() AS issued_rows,
        uniqExact(tuple(pol_prop_steadily_roof_condition_score_condition_score,prop_cov_roof_surfacing_exclusion,pol_ff_automated_roof_exclusion,pol_prop_steadily_roof_condition_score_decision,pol_prop_steadily_roof_condition_score_model_version,pol_prop_state,pol_prop_year_built,quote_id,pol_created_timestamp,quote_issued_timestamp)) AS distinct_states
 FROM dbt.ipod_standard_mga_raw_policy_info
 WHERE quote_type='NewBusiness' AND quote_status='Issued' AND quote_issued_timestamp IS NOT NULL
 GROUP BY policy_id,dwelling_id
), homes AS (
 SELECT policy_id,dwelling_id,b,issued_rows,distinct_states,
        tupleElement(b,1) AS score,tupleElement(b,2)='selected' AS rse,
        tupleElement(b,3) AS flag,tupleElement(b,4) AS decision,
        tupleElement(b,5) AS model_version,tupleElement(b,6) AS state,
        2026-tupleElement(b,7) AS age,tupleElement(b,7)>1700 AS valid_age,
        tupleElement(b,10) AS issue_ts
 FROM issued
), pol AS (
 SELECT policy_id,count() AS home_n,countIf(distinct_states>1) AS ambiguous_home_n,
        argMax(b,tuple(ifNull(score,-1),dwelling_id)) AS high_home,
        max(valid_age AND age>=101) AS any_101plus,
        max(rse) AS any_rse,max(flag='yes') AS any_flag_on,
        max(decision='exclude') AS any_issued_exclude,
        max(flag='yes' AND decision='exclude') AS any_issued_flag_on_exclude,
        min(issue_ts) AS first_issue_ts
 FROM homes GROUP BY policy_id
)
, coh AS (
 SELECT DISTINCT o_policy_id AS policy_id FROM dbt_dev.damr_uarnoe_cohort_20260816
 WHERE o_bind_ts>=toDateTime64('2026-04-01',6)
), noc AS (
 SELECT DISTINCT f_policy_id AS policy_id FROM dbt_dev.damr_uarnoe_final_20260816
 WHERE f_ev_class='cancellation' AND f_canc_reason='Inspection'
 AND f_uw_canc_reason='Condition - Roof' AND f_days_since_bind BETWEEN 0 AND 90
)
SELECT multiIf(tupleElement(p.high_home,1) IS NULL,'unscored',tupleElement(p.high_home,1)>=90,'90+',tupleElement(p.high_home,1)>=83,'83-89','below83') AS score_band,
       p.any_rse AS any_home_excluded_at_issue,p.any_101plus AS policy_has101plus,
       count() AS bound_policies,countIf(p.policy_id IN (SELECT policy_id FROM noc)) AS roof_cancellation_policies,
       countIf(p.ambiguous_home_n>0) AS ambiguous_policies,countIf(p.home_n=1) AS single_home_policies
FROM pol p INNER JOIN coh c ON c.policy_id=p.policy_id
GROUP BY score_band,any_home_excluded_at_issue,policy_has101plus;
-- Any excluded home is an explicit POLICY exposure definition, not an assertion the
-- highest-score home carried it. Run single-home sensitivity before interpreting differences.
-- This is association among bound survivors; coverage cannot mechanically prevent every
-- roof cancellation. Underlying roof hazards and inspection decisions remain possible.
