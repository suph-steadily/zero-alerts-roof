-- RUN 2026-09-23, database 235, SELECT only. L6 A28. Effective date and revision semantics from system column comments. Returned 9 metadata rows.
-- Expected: metadata and file dates, with no prespecified numeric result.
SELECT table,name,type,comment FROM system.columns WHERE database='dbt' AND table IN('claims_smga','ipod_standard_mga_raw_policy_info') AND name IN('claims_file','policy_inception','policy_expiration','quote_effective_timestamp','policy_effective_timestamp','policy_effective_end_timestamp','quote_issued_timestamp','quote_version','prop_cov_dwelling_limit','prop_cov_building_limit') ORDER BY table,name;

