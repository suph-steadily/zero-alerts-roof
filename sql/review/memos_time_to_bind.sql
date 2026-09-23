-- RUN 2026-09-23, first SELECT completed, 15 aggregate rows. Other SELECTs NOT RUN unless logged. Metabase db 235.
-- Purpose: Lane-specific conversion delays and fixed 14/30/60-day conversion, same quote denominator.
-- Claims: B20 A25 A29
-- Expected if the memo is right: Among issued 101+ quotes, medians 1-2 days; no claimed tail counts exist.
-- Lane remains inferred from current rows. The median among binders cannot establish maturation among all quotes.
-- A historical version source is needed to reconstruct removed/deleted historical quotes.
WITH q AS (
 SELECT quote_id, min(pol_created_timestamp) AS created,
 minIf(quote_issued_timestamp, quote_status='Issued' AND quote_issued_timestamp IS NOT NULL) AS issued_ts,
 countIf(quote_status='Issued' AND quote_issued_timestamp IS NOT NULL)>0 AS has_issue,
 max(prop_cov_roof_surfacing_exclusion='selected') AS has_rse,
 max(prop_cov_roof_surfacing_exclusion='selected' AND pol_ff_automated_roof_exclusion='yes' AND pol_prop_steadily_roof_condition_score_decision='exclude') AS is_auto
 FROM dbt.ipod_standard_mga_raw_policy_info
 WHERE quote_type='NewBusiness' AND pol_created_timestamp>=toDateTime('2026-04-01 00:00:00')
 AND pol_created_timestamp<toDateTime('2026-08-12 00:00:00')
 AND pol_prop_year_built>1700 AND 2026-pol_prop_year_built>=101
 GROUP BY quote_id
)
SELECT multiIf(is_auto,'auto',has_rse,'hand','none') AS lane,
 toStartOfMonth(created) AS creation_month, count() AS quotes,
 countIf(has_issue AND issued_ts>=created AND issued_ts<toDateTime('2026-08-26 00:00:00')) AS issued_by_cutoff,
 quantilesExactIf(0.5,0.9,0.95)(dateDiff('hour',created,issued_ts)/24.0,
 has_issue AND issued_ts>=created AND issued_ts<toDateTime('2026-08-26 00:00:00')) AS issued_delay_days,
 countIf(created<=toDateTime('2026-08-26 00:00:00')-INTERVAL 14 DAY) AS eligible_14d,
 countIf(created<=toDateTime('2026-08-26 00:00:00')-INTERVAL 14 DAY AND has_issue AND issued_ts>=created AND issued_ts<=created+INTERVAL 14 DAY) AS issued_14d,
 countIf(created<=toDateTime('2026-08-26 00:00:00')-INTERVAL 30 DAY) AS eligible_30d,
 countIf(created<=toDateTime('2026-08-26 00:00:00')-INTERVAL 30 DAY AND has_issue AND issued_ts>=created AND issued_ts<=created+INTERVAL 30 DAY) AS issued_30d,
 countIf(created<=toDateTime('2026-08-26 00:00:00')-INTERVAL 60 DAY) AS eligible_60d,
 countIf(created<=toDateTime('2026-08-26 00:00:00')-INTERVAL 60 DAY AND has_issue AND issued_ts>=created AND issued_ts<=created+INTERVAL 60 DAY) AS issued_60d
FROM q GROUP BY lane,creation_month ORDER BY lane,creation_month;
