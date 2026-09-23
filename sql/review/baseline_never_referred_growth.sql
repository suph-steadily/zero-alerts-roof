-- RUN 2026-09-23. Completed SELECTs; returned rows per statement: 5.
-- Purpose: compute the missing monthly 0.4%-5.0% never-referred auto signature series.
-- Claim IDs: S28 R2 A47.
-- Expected if the first read is right: an explicitly chosen first/last month yields
-- 0.4% and5.0% among101+ quotes with no referral submission in seven launch states.
-- Those month endpoints were not supplied. Output only aggregates, no identifiers.
WITH refs AS (
 SELECT DISTINCT JSONExtractString(data,'quote_id') AS quote_id
 FROM raw_pg_eventstore.eventstore_good_events
 WHERE name='underwriting_review_note'
 AND JSONExtractString(data,'action')='uw_note_submitted_and_review_requested'
 AND JSONExtractString(data,'category')='underwriting_review'
 AND created_at>=toDateTime('2026-03-01') AND created_at<toDateTime('2026-08-21')
), q AS (
 SELECT quote_id,toStartOfMonth(min(pol_created_timestamp)) AS creation_month,
        max(quote_status='Issued') AS issued,
        max(prop_cov_roof_surfacing_exclusion='selected' AND pol_ff_automated_roof_exclusion='yes'
            AND pol_prop_steadily_roof_condition_score_decision='exclude') AS auto_signature,
        uniqExact(pol_prop_state) AS state_count
 FROM dbt.ipod_standard_mga_raw_policy_info
 WHERE quote_type='NewBusiness' AND pol_created_timestamp>=toDateTime('2026-04-01')
 AND pol_created_timestamp<toDateTime('2026-08-16')
 AND pol_prop_year_built>1700 AND 2026-pol_prop_year_built>=101
 AND pol_prop_state IN ('AZ','NJ','PA','TN','NC','TX','CA')
 GROUP BY quote_id
)
SELECT creation_month,count() AS no_submission_quotes,sum(auto_signature) AS auto_signature_quotes,
       100.0*sum(auto_signature)/nullIf(count(),0) AS auto_share_pct,
       sum(issued) AS issued_quotes,countIf(state_count>1) AS multistate_quotes
FROM q WHERE quote_id NOT IN (SELECT quote_id FROM refs) GROUP BY creation_month;
-- No submission is a defined event proxy, not evidence no human saw the quote.
-- August is partial and all month cohorts mature differently. Actor/version/form
-- dependencies prevent interpreting this signature series as actual machine applies.
