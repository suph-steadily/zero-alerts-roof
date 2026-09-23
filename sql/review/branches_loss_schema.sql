-- RUN 2026-09-23, database 235, SELECT only; three statements returned 114 metadata rows, 223 table names and 4 aggregate ACV rows.
-- Purpose: L3/L5/L6/L14/L15, A22/A28/A31/A36/A43. Discover missing schema.
-- Expected: no numeric expectation. Live metadata resolves quote_version, effective
-- exposure dates, Coverage A field and monthly file basis; see branches_loss_date_metadata.sql.
-- BLOCKED: actor event semantics and complete causal covariate adjustment. Claim-home
-- ambiguity is zero in the corrected interval join; policy/term key remains useful.
-- The ACV option is known but its values and timing need verification.
SELECT database,table,name,type
FROM system.columns
WHERE (database='dbt' AND table IN ('ipod_standard_mga_raw_policy_info','claims_smga'))
  AND match(lower(name),'version|timestamp|effective|cancel|coverage|deduct|acv|paid|incurred|file|policy|claim|actor')
ORDER BY database,table,name;

SELECT database,name AS table_name
FROM system.tables
WHERE match(lower(name),'audit|history|actor|roof|claims.*file|manifest|coverage|endorse')
ORDER BY database,name;

SELECT prop_cov_roof_surfacing_loss_valuation_option AS acv_option,
       prop_cov_roof_surfacing_exclusion AS exclusion, count() AS source_rows,
       uniqExact(tuple(policy_id,dwelling_id)) AS homes
FROM dbt.ipod_standard_mga_raw_policy_info
WHERE quote_type='NewBusiness' AND quote_status='Issued'
  AND pol_created_timestamp>=toDateTime('2024-01-01 00:00:00','America/Chicago')
  AND pol_created_timestamp<toDateTime('2026-07-01 00:00:00','America/Chicago')
GROUP BY acv_option,exclusion ORDER BY acv_option,exclusion;

-- After discovery: actor check must find the first '' -> 'selected' version transition
-- within each issued home history, join its actor/event source, and aggregate by
-- first-apply year, actor class, rule/program ID category and claim peril group.
-- Limit to the excluded historical wind/hail claim cohort using the corrected window.
-- Output only counts and sums. 'inferred_hand' alone cannot establish who applied it.
-- Controls check: carry Coverage A, deductible, ACV and age on the SAME canonical
-- issued tuple; form state x bind-half x age-decade x Coverage-A-band x deductible
-- x ACV cells. Pre-specify bands, expose unmatched homes/exposure, and re-run
-- branches_loss_exposure.sql's standardization on those cells. Do not collapse missing
-- covariates into the control baseline. Audit age101+ at home grain separately.
