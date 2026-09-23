-- RUN 2026-09-23, first SELECT completed, 111 aggregate rows. Other SELECTs NOT RUN unless logged. Metabase db 235.
-- Purpose: Auto versus ALL non-auto quote traffic, by state, month and model version.
-- Claims: B13 B14 A2 A15
-- Expected if the memo is right: Before state cuts, printed counts give 199/527 vs 2583/7535 referred; 51/527 vs 898/7535 issued.
-- Current-row diagnostic only. No approval/referral conditioning and no hand exclusion from comparator.
-- Age is 2026 minus year built on qualifying dwellings. Non-auto includes hand plus none.
-- Mixed-state or mixed-version quotes are excluded explicitly; report their counts separately.
-- Decision-time version, event actor, and form eligibility remain BLOCKED pending schema discovery.
-- Historical as-of-Aug-25 bind state cannot be recovered from a drifting latest table alone.
WITH refs AS (
 SELECT DISTINCT JSONExtractString(data,'quote_id') AS quote_id
 FROM raw_pg_eventstore.eventstore_good_events
 WHERE name='underwriting_review_note'
 AND JSONExtractString(data,'action')='uw_note_submitted_and_review_requested'
 AND JSONExtractString(data,'category')='underwriting_review'
 AND created_at >= toDateTime('2026-03-01 00:00:00')
 AND created_at < toDateTime('2026-08-26 00:00:00')
), q AS (
 SELECT quote_id, min(toDate(pol_created_timestamp)) AS created,
 groupUniqArray(pol_prop_state) AS states, groupUniqArray(pol_prop_steadily_roof_condition_score_model_version) AS versions,
 max(quote_status='Issued') AS issued,
 max(prop_cov_roof_surfacing_exclusion='selected' AND pol_ff_automated_roof_exclusion='yes' AND pol_prop_steadily_roof_condition_score_decision='exclude' AND pol_prop_steadily_roof_condition_score_condition_score>=90) AS auto90,
 max(pol_prop_steadily_roof_condition_score_condition_score>=90) AS score90,
 min(pol_ff_automated_roof_exclusion='yes' AND pol_prop_state NOT IN ('CO','RI','WV')
 AND toDate(pol_created_timestamp)>=multiIf(pol_prop_state IN ('NJ','AZ'), toDate('2026-04-21'),
 pol_prop_state IN ('TN','PA','NC'), toDate('2026-04-30'),
 pol_prop_state IN ('CA','TX'), toDate('2026-05-11'), toDate('2026-07-30'))
 AND toDate(pol_created_timestamp) NOT IN (toDate('2026-04-27'),toDate('2026-04-28'),toDate('2026-05-29'))) AS all_rows_deployable
 FROM dbt.ipod_standard_mga_raw_policy_info
 WHERE quote_type='NewBusiness'
 AND pol_created_timestamp>=toDateTime('2026-04-01 00:00:00')
 AND pol_created_timestamp<toDateTime('2026-08-12 00:00:00')
 AND pol_prop_year_built>1700 AND 2026-pol_prop_year_built>=101
 GROUP BY quote_id
)
SELECT states[1] AS state, toStartOfMonth(created) AS creation_month,
 versions[1] AS model_version, if(auto90=1,'auto','non_auto_hand_plus_none') AS lane,
 count() AS quotes, countIf(quote_id IN (SELECT quote_id FROM refs)) AS referred_quotes,
 sum(issued) AS issued_quotes,
 100.0*referred_quotes/quotes AS referral_pct, 100.0*issued_quotes/quotes AS bind_pct
FROM q
WHERE score90=1 AND all_rows_deployable=1 AND length(states)=1 AND length(versions)=1
GROUP BY state, creation_month, model_version, lane
ORDER BY state, creation_month, model_version, lane;
