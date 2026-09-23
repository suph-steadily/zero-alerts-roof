-- RUN 2026-09-23. Completed SELECTs; returned rows per statement: 7, 120.
-- Purpose: Discover only schema, table availability and unknown historical/event dependencies.
-- Claim IDs: S10 S18 S19 S23 S24 S25 S28 RS19 Q2 A6 A8 A9 A10 A24
-- Expected if the first read is right: All three dbt_dev snapshots exist; 90-day completeness must use their documented extract cutoff, not their name.
-- Output is aggregate only. Live current rows cannot restore an earlier warehouse snapshot.

SELECT database, name AS table_name, engine
FROM system.tables
WHERE (database = 'dbt_dev' AND name IN ('damr_uarnoe_cohort_20260816', 'damr_uarnoe_final_20260816', 'damr_uarnoe_evdetail_20260816'))
   OR (database IN ('dbt', 'dbt_upc', 'raw_pg_eventstore') AND
       (positionCaseInsensitive(name, 'version') > 0 OR positionCaseInsensitive(name, 'audit') > 0 OR positionCaseInsensitive(name, 'letter') > 0));

SELECT database, table, name, type
FROM system.columns
WHERE (database = 'dbt' AND table = 'ipod_standard_mga_raw_policy_info'
       AND (match(name, '(?i)(timestamp|version|form|segment|eligible|roof|year_built|coverage|image|actor)')))
   OR (database = 'dbt_dev' AND table IN ('damr_uarnoe_cohort_20260816', 'damr_uarnoe_final_20260816', 'damr_uarnoe_evdetail_20260816'))
   OR (database = 'raw_pg_eventstore' AND table = 'eventstore_good_events')
ORDER BY database, table, name;
-- Blocked dependencies: a true quote-version timestamp/history key; event-to-dwelling key;
-- actor identity semantics; letter type and sent timestamp; snapshot observation cutoff;
-- eligible form/LD segment/coverage availability. Do not replace these with guessed columns.
-- Metadata only locates candidates. Validate the build recipe and meaning before using them.
