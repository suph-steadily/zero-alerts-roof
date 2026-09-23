-- Purpose: measure actual referral-decision latency, not assumed customer shopping elsewhere.
-- Claims P1,P2,P29,P31,A47. Expected: PRD says a day or two, without a denominator.
-- RUN 2026-09-23, 1 aggregate row: 16,783 referred quotes, 16,777 with a decision;
-- p50 6.8 minutes, p90 29.62 minutes; 81 decisions at least one day.
-- Original implicit date literals retained; first review OR immediate decision.
-- This tests timing only; no query can infer a causal incremental-bind effect
-- or an outside-shopping fact from these events. An alert-specific category and
-- event-sourced roof action census must be mapped before testing most-common UW action.
-- NB quotes with any valid 101+ home, age=2026-year_built; creations Apr1-Aug11 2026.
-- Referral and decisions observed through Aug25; first decision after first submission.
WITH q AS (
 SELECT quote_id,max(quote_status='Issued' AND quote_issued_timestamp<toDateTime('2026-08-26')) AS bound
 FROM dbt.ipod_standard_mga_raw_policy_info
 WHERE quote_type='NewBusiness'
 AND pol_created_timestamp>=toDateTime('2026-04-01')
 AND pol_created_timestamp<toDateTime('2026-08-12')
 AND pol_prop_year_built>1700 AND 2026-pol_prop_year_built>=101
 GROUP BY quote_id
), ev AS (
 SELECT JSONExtractString(data,'quote_id') AS quote_id,
   JSONExtractString(data,'action') AS action,created_at
 FROM raw_pg_eventstore.eventstore_good_events
 WHERE name='underwriting_review_note'
 AND JSONExtractString(data,'category')='underwriting_review'
 AND created_at>=toDateTime('2026-04-01') AND created_at<toDateTime('2026-08-26')
), submitted AS (
 SELECT quote_id,min(created_at) AS submitted_at FROM ev
 WHERE action='uw_note_submitted_and_review_requested' GROUP BY quote_id
), decision AS (
 SELECT s.quote_id,s.submitted_at,
  minIf(e.created_at,e.created_at>=s.submitted_at
     AND (e.action LIKE 'uw_review_decision_%' OR e.action LIKE 'uw_immediate_decision_%')) AS first_decision,
  countIf(e.created_at>=s.submitted_at
     AND (e.action LIKE 'uw_review_decision_%' OR e.action LIKE 'uw_immediate_decision_%')) AS decisions
 FROM submitted s LEFT JOIN ev e ON e.quote_id=s.quote_id GROUP BY s.quote_id,s.submitted_at
)
SELECT count() AS referred_quotes,sum(q.bound) AS bound_referred_quotes,
 countIf(d.decisions=0) AS still_without_decision,
 quantilesExactIf(0.5,0.9)(dateDiff('second',d.submitted_at,d.first_decision)/3600.,d.decisions>0) AS latency_hours_p50_p90,
 countIf(d.decisions>0 AND dateDiff('second',d.submitted_at,d.first_decision)>=86400) AS waits_at_least_one_day
FROM q INNER JOIN decision d ON d.quote_id=q.quote_id;
