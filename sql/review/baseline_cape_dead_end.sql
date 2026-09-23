-- RUN 2026-09-23. Completed SELECTs; returned rows per statement: 1, 41.
-- Purpose: Check the recorded CAPE-only dead end without exporting rows.
-- Claim IDs: S20
-- Expected if the first read is right: 562744 rows, all has_cape_data=1 at the historical check; live count may drift.
-- Output is aggregate only. Live current rows cannot restore an earlier warehouse snapshot.

SELECT count() AS rows_,countIf(has_cape_data=1) AS cape_rows
FROM dbt_data_science.fct_roof_exclusion;
SELECT name,type FROM system.columns
WHERE database='dbt_data_science' AND table='fct_roof_exclusion'
ORDER BY name;
