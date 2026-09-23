-- RUN 2026-09-23, first SELECT completed, 20 aggregate rows. Other SELECTs NOT RUN unless logged. Metabase db 235.
-- Purpose: Actual no-alert/no-note proxy, all ages and 101+, by both creation and issue month.
-- Claims: O9 O10 A41
-- Expected if the memo is right: Original all-age creation-month totals/strict proxy: Apr7/3, May83/48, Jun131/66, Jul105/69, Aug67/54.
-- This counts absence of alert/note evidence, not actual absence of roof review.
-- 101+ cut tests excluded dwelling rows, so it excludes auto coverage solely on a younger sibling.
-- Original Q8 had no upper issue cutoff; this fixed cutoff may differ for late converters.
-- Alert records lack an established as-of timestamp in checked-in SQL; historical gate status is not guaranteed.
WITH q AS (
 SELECT quote_id,min(pol_created_timestamp) AS created,min(quote_issued_timestamp) AS issued,
 max(pol_prop_year_built>1700 AND 2026-pol_prop_year_built>=101) AS any101
 FROM dbt.ipod_standard_mga_raw_policy_info WHERE quote_type='NewBusiness' AND quote_status='Issued'
 AND pol_created_timestamp>=toDateTime('2026-04-01 00:00:00')
 AND pol_created_timestamp<toDateTime('2026-08-26 00:00:00')
 AND quote_issued_timestamp<toDateTime('2026-08-26 00:00:00')
 AND pol_ff_automated_roof_exclusion='yes' AND pol_prop_steadily_roof_condition_score_decision='exclude' AND prop_cov_roof_surfacing_exclusion='selected'
 GROUP BY quote_id
), gates AS (
 SELECT quote_id,max(toUInt8(requires_uw_review)) AS gated FROM dbt_upc.uw_alerts_per_quote
 WHERE alert_category NOT IN ('DATA_SAFEGUARD','VALIDATION','SHOWSTOPPER','SYSTEM_ERROR') GROUP BY quote_id
), refs AS (
 SELECT DISTINCT JSONExtractString(data,'quote_id') AS quote_id
 FROM raw_pg_eventstore.eventstore_good_events WHERE name='underwriting_review_note'
 AND created_at>=toDateTime('2026-03-15 00:00:00') AND created_at<toDateTime('2026-08-26 00:00:00')
), j AS (
 SELECT q.*,coalesce(g.gated,0) AS gated,
 q.quote_id IN (SELECT quote_id FROM refs) AS has_note,
 arrayJoin(if(any101,['all_ages','101+'],['all_ages'])) AS population,
 arrayJoin(['creation','issue']) AS clock
 FROM q LEFT JOIN gates g ON q.quote_id=g.quote_id
)
SELECT population,clock,toStartOfMonth(if(clock='creation',created,issued)) AS month,
 count() AS auto_excluded_quotes,countIf(NOT gated AND NOT has_note) AS no_gate_no_note_quotes
FROM j GROUP BY population,clock,month ORDER BY population,clock,month;
