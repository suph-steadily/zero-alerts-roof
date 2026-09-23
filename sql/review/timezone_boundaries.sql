-- Purpose: diagnose literal/session versus timestamp-column calendar boundaries.
-- Claims: Q1, A15, A25, A40. Expected: a consistent July30-Aug31 window has no September bucket.
-- RUN 2026-09-23, 3 aggregate rows. Original implicit literal predicate admitted
-- 229 all-age NB rows displayed as September1 00:00-04:59. Server zone America/Chicago.
-- Diagnostic only; corrected new cohorts should declare one zone in predicates AND grouping.
SELECT timezone() AS server_timezone,
 any(toTypeName(pol_created_timestamp)) AS ts_type,
 toString(min(pol_created_timestamp)) AS min_ts,
 toString(max(pol_created_timestamp)) AS max_ts,
 toString(toStartOfMonth(pol_created_timestamp)) AS month_string,
 count() AS n
FROM dbt.ipod_standard_mga_raw_policy_info
WHERE quote_type='NewBusiness'
 AND pol_created_timestamp>=toDateTime('2026-07-30')
 AND pol_created_timestamp<toDateTime('2026-09-01')
GROUP BY month_string ORDER BY month_string;
