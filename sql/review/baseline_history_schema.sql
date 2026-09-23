-- RUN 2026-09-23. Completed SELECTs; returned rows per statement: 47.
-- Purpose: find version timestamp and actor metadata after initial discovery.
-- Claim IDs: A6 A16 A19 A39. Expected: mappings only, not a historical state census.
SELECT database,table,name,type FROM system.columns WHERE database='dbt' AND table IN ('ipod_attributed_audit_per_quote_version','ipod_smga_uw_alerts_per_quote_version','nicole_audit_logs') ORDER BY table,name;
