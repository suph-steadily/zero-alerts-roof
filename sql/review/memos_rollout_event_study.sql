-- RUN 2026-09-23, first SELECT completed, 1006 aggregate rows. Other SELECTs NOT RUN unless logged. Metabase db 235.
-- Purpose: Within-state weekly event-time counts and fixed 30-day bind outcome, including April.
-- Claims: O1 O2 O3 A12 A15
-- Expected if the memo is right: May/June/July original raw gaps are -0.25/-0.69/-1.12pp; April unknown.
-- Current-row intent-to-treat proxy, not random assignment or causality.
-- Do not call flag-on exclude quotes auto-applied without selected coverage.
-- Event-time trends should be inspected separately by state and decision; do not assume the pass trend is parallel.
-- Eligible forms and decision-time assignment require the discovered event/version schema.
WITH q AS (
 SELECT quote_id,min(pol_created_timestamp) AS created,groupUniqArray(pol_prop_state) AS states,
 max(quote_status='Issued') AS issued,
 minIf(quote_issued_timestamp,quote_status='Issued' AND quote_issued_timestamp IS NOT NULL) AS issue_ts,
 max(pol_ff_automated_roof_exclusion='yes') AS flag_on,
 max(pol_prop_steadily_roof_condition_score_decision='exclude') AS exclude_decision,max(pol_prop_steadily_roof_condition_score_decision='pass') AS pass_decision,
 max(pol_ff_automated_roof_exclusion='yes' AND pol_prop_steadily_roof_condition_score_decision='exclude') AS same_row_exclude,
 max(pol_prop_year_built>1700 AND 2026-pol_prop_year_built>=101) AS any101
 FROM dbt.ipod_standard_mga_raw_policy_info WHERE quote_type='NewBusiness'
 AND pol_created_timestamp>=toDateTime('2026-04-01 00:00:00')
 AND pol_created_timestamp<toDateTime('2026-08-01 00:00:00')
 AND toDate(pol_created_timestamp) NOT IN (toDate('2026-04-27'),toDate('2026-04-28'),toDate('2026-05-29'))
 GROUP BY quote_id
), e AS (
 SELECT *,states[1] AS state,
 multiIf(state IN ('NJ','AZ'),toDate('2026-04-21'),state IN ('TN','PA','NC'),toDate('2026-04-30'),
 state IN ('CA','TX'),toDate('2026-05-11'),toDate('2026-07-30')) AS wave,
 arrayJoin(if(any101,['all_ages','101+'],['all_ages'])) AS population
 FROM q WHERE length(states)=1 AND states[1] IN ('NJ','AZ','TN','PA','NC','CA','TX')
)
SELECT population,state,wave,toStartOfMonth(created) AS creation_month,
 floor(dateDiff('day',wave,toDate(created))/7.0) AS relative_week,
 multiIf(exclude_decision,'exclude',pass_decision,'pass','other') AS decision,flag_on,
 count() AS quotes,sum(issued) AS current_issued,
 countIf(created<=toDateTime('2026-08-26 00:00:00')-INTERVAL 30 DAY) AS full_30d_quotes,
 countIf(created<=toDateTime('2026-08-26 00:00:00')-INTERVAL 30 DAY AND issued
 AND issue_ts>=created AND issue_ts<=created+INTERVAL 30 DAY) AS issued30,
 countIf(exclude_decision AND flag_on AND NOT same_row_exclude) AS stitched_signatures
FROM e GROUP BY population,state,wave,creation_month,relative_week,decision,flag_on
ORDER BY population,state,creation_month,relative_week,decision,flag_on;
