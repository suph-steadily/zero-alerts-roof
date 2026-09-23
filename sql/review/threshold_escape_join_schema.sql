-- RUN 2026-09-23, completed, 104 aggregate/schema rows. Metabase db 235; SELECT only.
-- Resolve property join and Cape availability timestamp before interpreting roof-year/inspection comparisons.
SELECT database,table,name,type,comment FROM system.columns
WHERE (database='dbt' AND table='pl_schedule')
 OR (database='dbt_upc' AND table='ipod_policy_mga_cape' AND NOT match(name,'^roof|^accessory'))
ORDER BY database,table,name;
