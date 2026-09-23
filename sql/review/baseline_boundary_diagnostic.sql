-- RUN 2026-09-23. Completed SELECTs; returned rows per statement: 1.
-- Purpose: show implicit time conversion changes cohort membership.
-- Claim IDs: R3 Q1 A21. Expected: equality only after one explicit timezone is used.
SELECT countIf(pol_created_timestamp>=toDateTime('2026-05-01')) AS timestamp_cut,countIf(toDate(pol_created_timestamp)>=toDate('2026-05-01')) AS date_cut, countIf(toDate(pol_created_timestamp)>=toDate('2026-05-01') AND pol_created_timestamp<toDateTime('2026-05-01')) AS extra_date_cut FROM dbt.ipod_standard_mga_raw_policy_info WHERE quote_type='NewBusiness' AND quote_status='Issued' AND pol_created_timestamp>=toDateTime('2026-04-01') AND pol_created_timestamp<toDateTime('2026-08-16') AND pol_prop_year_built>1700 AND 2026-pol_prop_year_built>=101;
