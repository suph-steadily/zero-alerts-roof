-- RUN 2026-09-23. Completed SELECTs; returned rows per statement: 93.
-- Purpose: supply numerator and candidate denominators for external53-59% statement.
-- Claim IDs: S10 S18 S19 S25 A47.
-- Expected if the first read is right: after a domain owner identifies which event
-- classes are UW corrective endorsement transactions, roof-add transactions comprise
--53-59% in the stated Jan-May snapshot cohorts. No such class definition is in repo.
WITH roof_add AS (
 SELECT DISTINCT e_quote_id FROM dbt_dev.damr_uarnoe_evdetail_20260816
 WHERE e_col='roof_surfacing_exclusion' AND e_prev='' AND e_cur='selected'
)
SELECT f_cohort,toStartOfMonth(f_bind_ts) AS snapshot_bind_month,f_ev_class,
       count() AS uw_event_rows,uniqExact(f_ev_quote_id) AS uw_event_quotes,
       uniqExact(f_policy_id) AS uw_event_policies,
       countIf(f_ev_quote_id IN (SELECT e_quote_id FROM roof_add)) AS roof_add_event_rows,
       uniqExactIf(f_ev_quote_id,f_ev_quote_id IN (SELECT e_quote_id FROM roof_add)) AS roof_add_event_quotes
FROM dbt_dev.damr_uarnoe_final_20260816
WHERE f_actor_class='uw' AND f_days_since_bind BETWEEN 0 AND 90
GROUP BY f_cohort,snapshot_bind_month,f_ev_class;
-- This is a class census, not confirmation of the percentage. Verify event-quote
-- uniqueness, corrective class membership and observation window before summing cells.
-- Actual NOE letters require a separate sent-letter table and denominator.
