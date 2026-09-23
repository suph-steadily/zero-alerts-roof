-- RUN 2026-09-23, first SELECT completed, 7 aggregate rows. Other SELECTs NOT RUN unless logged. Metabase db 235.
-- Purpose: Count latest UW decisions when the submission event is missing.
-- Claims: B7 B8 B17
-- Expected if the memo is right: Hand 178 missing submissions/87 issued; 23 approved/11 issued, none 24 approved/5 issued.
-- Current-row quote lanes only. A missing submission is not evidence of no contact.
-- Actor roles are BLOCKED until event actor IDs can be mapped to validated role classes without publishing identities.
WITH refs AS (
 SELECT DISTINCT JSONExtractString(data,'quote_id') AS quote_id
 FROM raw_pg_eventstore.eventstore_good_events
 WHERE name='underwriting_review_note'
 AND JSONExtractString(data,'action')='uw_note_submitted_and_review_requested'
 AND JSONExtractString(data,'category')='underwriting_review'
 AND created_at>=toDateTime('2025-06-01 00:00:00') AND created_at<toDateTime('2026-08-26 00:00:00')
), decisions AS (
 SELECT JSONExtractString(data,'quote_id') AS quote_id,
 argMax(JSONExtractString(data,'action'),created_at) AS action
 FROM raw_pg_eventstore.eventstore_good_events
 WHERE name='underwriting_review_note' AND JSONExtractString(data,'category')='underwriting_review'
 AND (JSONExtractString(data,'action') LIKE 'uw_review_decision_%' OR JSONExtractString(data,'action') LIKE 'uw_immediate_decision_%')
 AND created_at>=toDateTime('2025-06-01 00:00:00') AND created_at<toDateTime('2026-08-26 00:00:00')
 GROUP BY quote_id
), q AS (
 SELECT quote_id,max(quote_status='Issued') AS issued,
 max(prop_cov_roof_surfacing_exclusion='selected') AS rse,
 max(prop_cov_roof_surfacing_exclusion='selected' AND pol_ff_automated_roof_exclusion='yes' AND pol_prop_steadily_roof_condition_score_decision='exclude') AS auto
 FROM dbt.ipod_standard_mga_raw_policy_info WHERE quote_type='NewBusiness'
 AND pol_created_timestamp>=toDateTime('2026-04-01 00:00:00')
 AND pol_created_timestamp<toDateTime('2026-08-12 00:00:00')
 AND pol_prop_year_built>1700 AND 2026-pol_prop_year_built>=101 GROUP BY quote_id
)
SELECT multiIf(q.auto,'auto',q.rse,'hand','none') AS lane,
 coalesce(d.action,'(no_decision)') AS latest_decision,count() AS quotes,sum(q.issued) AS issued_quotes
FROM q LEFT JOIN decisions d ON q.quote_id=d.quote_id
WHERE q.quote_id NOT IN (SELECT quote_id FROM refs)
GROUP BY lane,latest_decision ORDER BY lane,latest_decision
SETTINGS join_use_nulls=1;

-- Staff/agent submission share needs a validated actor mapping. Discover keys, not actor values.
SELECT name,arraySort(arrayDistinct(arrayFlatten(groupArray(JSONExtractKeys(data))))) AS payload_keys,count() AS events
FROM raw_pg_eventstore.eventstore_good_events
WHERE name='underwriting_review_note' AND JSONExtractString(data,'action')='uw_note_submitted_and_review_requested'
AND created_at>=toDateTime('2026-04-01 00:00:00') AND created_at<toDateTime('2026-08-26 00:00:00') GROUP BY name;
