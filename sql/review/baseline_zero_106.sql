-- RUN 2026-09-23. Completed SELECTs; returned rows per statement: 4.
-- Purpose: Reproduce 0/106, 12 at95+, 1/106 both issued-row and any NB-version ways, with age/flag cuts.
-- Claim IDs: RS30 S14 P6 A11
-- Expected if the first read is right: Legacy April+ snapshot all ages: 106 cancellation policies, 12 score95+, zero exclude, one bind exclusion. None is assumed true.
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
, noc AS (
 SELECT f_policy_id AS policy_id,min(f_bind_ts) AS bind_ts
 FROM dbt_dev.damr_uarnoe_final_20260816
 WHERE f_ev_class='cancellation' AND f_canc_reason='Inspection'
 AND f_uw_canc_reason='Condition - Roof' AND f_days_since_bind BETWEEN 0 AND 90
 GROUP BY f_policy_id HAVING toDate(bind_ts)>=toDate('2026-04-01')
), all_nb AS (
 SELECT policy_id,countIf(pol_prop_steadily_roof_condition_score_decision='exclude')>0 AS ever_exclude,
        countIf(pol_ff_automated_roof_exclusion='yes' AND pol_prop_steadily_roof_condition_score_decision='exclude')>0 AS ever_flag_on_exclude,
        max(pol_prop_steadily_roof_condition_score_decision) AS legacy_string_max_decision,
        max(pol_prop_steadily_roof_condition_score_condition_score) AS legacy_max_score,
        max(prop_cov_roof_surfacing_exclusion='selected') AS any_version_rse
 FROM dbt.ipod_standard_mga_raw_policy_info WHERE quote_type='NewBusiness'
 AND policy_id IN (SELECT policy_id FROM noc) GROUP BY policy_id
), expanded AS (
 SELECT p.home_n AS home_n,p.ambiguous_home_n AS ambiguous_home_n,p.high_home AS high_home,
        p.any_issued_exclude AS any_issued_exclude,p.any_issued_flag_on_exclude AS any_issued_flag_on_exclude,
        p.any_rse AS any_rse,a.ever_exclude AS ever_exclude,a.ever_flag_on_exclude AS ever_flag_on_exclude,
        a.legacy_string_max_decision AS legacy_string_max_decision,a.legacy_max_score AS legacy_max_score,
        a.any_version_rse AS any_version_rse,arrayJoin(['all_ages','101plus_any_home']) AS age_cut,
        arrayJoin(['all_flags','issued_any_flag_on']) AS flag_cut
 FROM noc n LEFT JOIN pol p ON p.policy_id=n.policy_id LEFT JOIN all_nb a ON a.policy_id=n.policy_id
 WHERE (age_cut='all_ages' OR p.any_101plus=1) AND (flag_cut='all_flags' OR p.any_flag_on=1)
)
SELECT age_cut,flag_cut,count() AS cancellation_policies,
       countIf(home_n=0) AS no_issued_home,
       countIf(ambiguous_home_n>0) AS ambiguous_issued_policy,
       countIf(any_issued_exclude=1) AS issued_any_home_exclude,
       countIf(any_issued_flag_on_exclude=1) AS issued_same_home_flag_on_exclude,
       countIf(ever_exclude=1) AS any_nb_version_exclude,
       countIf(ever_flag_on_exclude=1) AS any_nb_version_same_row_flag_on_exclude,
       countIf(legacy_string_max_decision='exclude') AS legacy_max_string_exclude,
       countIf(tupleElement(high_home,1)>=95) AS issued_policy_high_score95,
       countIf(legacy_max_score>=95) AS any_nb_max_score95,
       countIf(legacy_max_score>=83) AS any_nb_max_score83,
       countIf(tupleElement(high_home,1)>=83) AS issued_high_home_score83,
       countIf(any_rse=1) AS issued_any_home_excluded,
       countIf(any_version_rse=1) AS any_nb_version_excluded
FROM expanded GROUP BY age_cut,flag_cut;
-- all_nb means all retained NB records, NOT guaranteed complete historical versions.
-- Current-row storage may have overwritten past decisions. The ANY-version result is an
-- upper bound only relative to the retained rows, not to the full event history.
-- No causal prevention claim follows, even if the historical numerator remains zero.
