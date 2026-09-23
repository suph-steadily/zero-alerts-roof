-- RUN 2026-09-23, first SELECT 70 aggregate rows; schema SELECT 28 rows. Metabase db 235.
-- Purpose: Separate TX no-decision from exclude-without-coverage, by age and month.
-- Claims: B19 O1 A6 A13
-- Expected if the memo is right: TX has zero selected auto exclusions, despite flag-on launch May 11.
-- BLOCKED: LD segment, form availability, condo eligibility, rule inputs and exclusion transitions are undocumented.
-- The discovery SELECT is exact; do not invent these columns or treat a zero as evidence of its cause.
-- Next join validated segment/form/rule fields on the same decision-time dwelling version; report aggregate reason counts.
-- The 171 flag-on exclude quotes without coverage are all ages, Apr-Jul 2026; this TX diagnostic is a component, not their full reconciliation.
SELECT toStartOfMonth(pol_created_timestamp) AS creation_month,
 if(2026-pol_prop_year_built>=101,'101+','under101') AS age_band,
 pol_prop_steadily_roof_condition_score_model_version AS model_version, pol_ff_automated_roof_exclusion AS automation_flag, pol_prop_steadily_roof_condition_score_decision AS model_decision,
 count() AS dwelling_rows, uniqExact(quote_id) AS quotes,
 countIf(prop_cov_roof_surfacing_exclusion='selected') AS selected_rows,
 countIf(pol_prop_steadily_roof_condition_score_condition_score>=95) AS score95_rows
FROM dbt.ipod_standard_mga_raw_policy_info
WHERE quote_type='NewBusiness' AND pol_prop_state='TX' AND pol_prop_year_built>1700
AND pol_created_timestamp>=toDateTime('2026-05-11 00:00:00')
AND pol_created_timestamp<toDateTime('2026-08-12 00:00:00')
AND toDate(pol_created_timestamp)!=toDate('2026-05-29')
GROUP BY creation_month,age_band,model_version,automation_flag,model_decision
ORDER BY creation_month,age_band,model_version,automation_flag,model_decision;

SELECT database,table,name,type FROM system.columns
WHERE (database='dbt' AND table='ipod_standard_mga_raw_policy_info')
AND match(lower(name),'segment|form|condo|roof|eligib|product')
ORDER BY name;
