-- RUN 2026-09-23. Completed SELECTs; returned rows per statement: 18, 7.
-- Purpose: Rebuild policy and home overlay from one coherent issued tuple with explicit ambiguity and April denominators.
-- Claim IDs: S7 S8 S9 S11 RS16 RS18 RS19 RS20 RS21 Q2 A19
-- Expected if the first read is right: Original legacy all-age snapshot: April+ 633 endorsement policies and 106 cancellation policies; corrected issued tuple numbers may change. Missing or ambiguous records block acceptance.
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
,
roof_add AS (
 SELECT DISTINCT e_quote_id FROM dbt_dev.damr_uarnoe_evdetail_20260816
 WHERE e_col='roof_surfacing_exclusion' AND e_prev='' AND e_cur='selected'
), events AS (
 SELECT f_policy_id AS policy_id,'roof_corrective_endorsement_transaction' AS kind,
        f_days_since_bind AS days_since_bind,f_bind_ts AS snapshot_bind_ts,f_cohort AS cohort
 FROM dbt_dev.damr_uarnoe_final_20260816
 WHERE f_actor_class='uw' AND f_ev_quote_id IN (SELECT e_quote_id FROM roof_add)
 UNION ALL
 SELECT f_policy_id,'roof_cancellation_transaction',f_days_since_bind,f_bind_ts,f_cohort
 FROM dbt_dev.damr_uarnoe_final_20260816
 WHERE f_ev_class='cancellation' AND f_canc_reason='Inspection' AND f_uw_canc_reason='Condition - Roof'
), event_policy AS (
 SELECT policy_id,kind,cohort,min(snapshot_bind_ts) AS snapshot_bind_ts,
        min(days_since_bind) AS first_day,count() AS event_rows
 FROM events WHERE days_since_bind BETWEEN 0 AND 90 GROUP BY policy_id,kind,cohort
)
, expanded AS (
 SELECT e.*,p.home_n,p.ambiguous_home_n,p.any_101plus,
        tupleElement(p.high_home,1) AS score,p.first_issue_ts,
        arrayJoin(['all_ages','101plus_policy_any_home']) AS age_cut,
        arrayJoin([60,90]) AS horizon
 FROM event_policy e LEFT JOIN pol p ON p.policy_id=e.policy_id
 WHERE (age_cut='all_ages' OR p.any_101plus=1) AND e.first_day<=horizon
)
SELECT 'policy' AS grain,kind,cohort,age_cut,horizon,
       count() AS event_policies_all_eras,
       countIf(home_n=0) AS unmatched_policies,
       countIf(ambiguous_home_n>0) AS ambiguous_policies,
       countIf(toDate(snapshot_bind_ts)>=toDate('2026-04-01')) AS april_plus_policies,
       countIf(toDate(snapshot_bind_ts)>=toDate('2026-04-01') AND score IS NOT NULL) AS april_plus_scored,
       countIf(toDate(snapshot_bind_ts)>=toDate('2026-04-01') AND score>=60) AS april_ge60,
       countIf(toDate(snapshot_bind_ts)>=toDate('2026-04-01') AND score>=70) AS april_ge70,
       countIf(toDate(snapshot_bind_ts)>=toDate('2026-04-01') AND score>=75) AS april_ge75,
       countIf(toDate(snapshot_bind_ts)>=toDate('2026-04-01') AND score>=80) AS april_ge80,
       countIf(toDate(snapshot_bind_ts)>=toDate('2026-04-01') AND score>=85) AS april_ge85,
       countIf(toDate(snapshot_bind_ts)>=toDate('2026-04-01') AND score>=90) AS april_ge90,
       countIf(toDate(first_issue_ts)!=toDate(snapshot_bind_ts)) AS snapshot_vs_issue_date_mismatch,
       countIf(home_n=1) AS single_home_policies,
       sum(event_rows) AS events_before_policy_dedupe
FROM expanded GROUP BY kind,cohort,age_cut,horizon;

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
,
roof_add AS (
 SELECT DISTINCT e_quote_id FROM dbt_dev.damr_uarnoe_evdetail_20260816
 WHERE e_col='roof_surfacing_exclusion' AND e_prev='' AND e_cur='selected'
), events AS (
 SELECT f_policy_id AS policy_id,'roof_corrective_endorsement_transaction' AS kind,
        f_days_since_bind AS days_since_bind,f_bind_ts AS snapshot_bind_ts,f_cohort AS cohort
 FROM dbt_dev.damr_uarnoe_final_20260816
 WHERE f_actor_class='uw' AND f_ev_quote_id IN (SELECT e_quote_id FROM roof_add)
 UNION ALL
 SELECT f_policy_id,'roof_cancellation_transaction',f_days_since_bind,f_bind_ts,f_cohort
 FROM dbt_dev.damr_uarnoe_final_20260816
 WHERE f_ev_class='cancellation' AND f_canc_reason='Inspection' AND f_uw_canc_reason='Condition - Roof'
), event_policy AS (
 SELECT policy_id,kind,cohort,min(snapshot_bind_ts) AS snapshot_bind_ts,
        min(days_since_bind) AS first_day,count() AS event_rows
 FROM events WHERE days_since_bind BETWEEN 0 AND 90 GROUP BY policy_id,kind,cohort
)

SELECT e.kind,e.cohort,
       if(h.valid_age AND h.age>=101,'101plus_home','other_or_unknown_home') AS home_age_cut,
       count() AS homes_attached_to_harmed_policies,
       uniqExact(e.policy_id) AS distinct_harmed_policies,
       countIf(h.distinct_states>1) AS ambiguous_homes,
       countIf(h.score IS NOT NULL) AS scored_homes,
       countIf(h.score>=80) AS homes_ge80,
       countIf(p.home_n=1) AS single_home_policy_homes
FROM event_policy e INNER JOIN homes h ON h.policy_id=e.policy_id
INNER JOIN pol p ON p.policy_id=e.policy_id
WHERE toDate(e.snapshot_bind_ts)>=toDate('2026-04-01')
GROUP BY e.kind,e.cohort,home_age_cut;
-- Age: 2026-year_built per home, with any-101+ rollup explicitly labelled. The high_home
-- tuple is one real home, never max() of separate attributes. Multiple issued states,
-- null issue timestamps or snapshot/issue mismatches require history repair before use.
-- Home output is association with a harmed POLICY, not proof this home caused the event.
-- The detail join is quote-grain, not proven event-grain; run snapshot diagnostics first.
-- No fixed observation cutoff can be inferred from max(event time), so 60/90 similarities
-- do not establish maturity. Discover and declare the frozen snapshot cutoff first.
