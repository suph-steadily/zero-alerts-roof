-- RUN 2026-09-23. Completed SELECTs; returned rows per statement: 5.
-- Purpose: Recreate historical snapshot removal actor census and bind-signature 9/1 split.
-- Claim IDs: S2 S26 RS36 Q4 R2 A8
-- Expected if the first read is right: 64 removal event rows,63 policies; actor counts28 UW,22 agent,9 CX,5 other; nine bind-excluded policies and one auto signature claimed. No denominator/causal objection inference.
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
, rem AS (
 SELECT DISTINCT e_quote_id FROM dbt_dev.damr_uarnoe_evdetail_20260816
 WHERE e_col='roof_surfacing_exclusion' AND e_prev='selected' AND e_cur=''
), p_auto AS (
 SELECT policy_id,max(rse AND flag='yes' AND decision='exclude') AS any_bind_auto
 FROM homes GROUP BY policy_id
)
SELECT f.f_actor_class,count() AS removal_event_rows,uniqExact(f.f_policy_id) AS removal_policies,
       uniqExactIf(f.f_policy_id,p.any_rse=1) AS bind_excluded_removal_policies,
       uniqExactIf(f.f_policy_id,a.any_bind_auto=1) AS bind_auto_signature_removal_policies,
       countIf(f.f_days_since_bind BETWEEN 0 AND 90) AS removal_event_rows_0_90,
       countIf(p.ambiguous_home_n>0) AS ambiguous_bind_event_rows
FROM dbt_dev.damr_uarnoe_final_20260816 f
INNER JOIN rem r ON r.e_quote_id=f.f_ev_quote_id
LEFT JOIN pol p ON p.policy_id=f.f_policy_id
LEFT JOIN p_auto a ON a.policy_id=f.f_policy_id
GROUP BY f.f_actor_class;
-- Historical snapshot universe and no time-window restriction match the old actor census.
-- Also prints 0-90 days. A policy-level match cannot establish same-home removal; actor
-- semantics and audit-log linkage are unresolved. This is NOT the live October re-pull.
