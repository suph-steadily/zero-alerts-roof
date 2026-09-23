-- RUN 2026-09-23. Completed SELECTs; returned rows per statement: 1, 7, 1.
-- Purpose: Measure snapshot cohort/event grain, roof-add class, actor and score-era timing gaps.
-- Claim IDs: S10 S18 S19 S23 S24 S25 RS19 RS20 Q2 Q4 A8 A10 A24 A26
-- Expected if the first read is right: Cohort historically 47256 policies; roof-add attribute_correction=9; median transaction lag35-38 days. Letters and extract cutoff require separate sources.
-- Output is aggregate only. Live current rows cannot restore an earlier warehouse snapshot.

SELECT count() AS cohort_rows,uniqExact(o_policy_id) AS cohort_policies,
       min(o_bind_ts) AS earliest_snapshot_bind,max(o_bind_ts) AS latest_snapshot_bind
FROM dbt_dev.damr_uarnoe_cohort_20260816;

WITH roof_add AS (
 SELECT DISTINCT e_quote_id FROM dbt_dev.damr_uarnoe_evdetail_20260816
 WHERE e_col='roof_surfacing_exclusion' AND e_prev='' AND e_cur='selected'
)
SELECT f_cohort,f_ev_class,f_actor_class,count() AS event_rows,uniqExact(f_policy_id) AS policies,
       uniqExact(f_ev_quote_id) AS event_quotes,
       countIf(f_days_since_bind BETWEEN 0 AND 90) AS events_0_90,
       quantileExact(0.5)(f_days_since_bind) AS median_days_since_snapshot_bind,
       min(f_bind_ts) AS earliest_bind,max(f_bind_ts) AS latest_bind
FROM dbt_dev.damr_uarnoe_final_20260816
WHERE f_ev_quote_id IN (SELECT e_quote_id FROM roof_add)
GROUP BY f_cohort,f_ev_class,f_actor_class;

WITH counts AS (
 SELECT f_ev_quote_id,count() AS final_rows,
        uniqExact(tuple(f_policy_id,f_ev_class,f_days_since_bind,f_actor_class)) AS distinct_event_states
 FROM dbt_dev.damr_uarnoe_final_20260816 GROUP BY f_ev_quote_id
)
SELECT count() AS event_quote_keys,countIf(final_rows>1) AS multirow_quote_keys,
       countIf(distinct_event_states>1) AS ambiguous_quote_event_keys,max(final_rows) AS max_rows_per_event_quote
FROM counts;
-- A filename date is NOT an observation-end date. The last observed event is not a
-- no-event observation guarantee. Read the snapshot build manifest before quoting runway.
-- If the inclusive observation cutoff is 2026-08-15, the last fully observed 90-day
-- bind date is 2026-05-17; earlier cutoff moves that date earlier. May22 assumed Aug20.
-- 53-59% of all UW corrective endorsement transactions needs a validated definition of
-- corrective event class; the repo does not provide that population. Do not invent it.
-- NOC and NOE are letters. These snapshot queries count transactions, not sent letters.
