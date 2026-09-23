-- RUN 2026-09-23, completed, 518 aggregate/schema rows. Metabase db 235; SELECT only.
-- Purpose: discover full roof replacement, roof age/material, attestation and inspection join/timing fields.
-- Expected: known MGA roof_age String and material fields; existence does not establish full-replacement semantics.
-- Schema metadata only. No event payloads, entity IDs, addresses, names or record extracts returned.
SELECT database,table,name,type,comment
FROM system.columns
WHERE database IN ('dbt','dbt_upc','raw_pg_eventstore','tap_veruna')
AND (
 (table IN ('ipod_standard_mga_raw_policy_info','socotra_raw_quote_info','socotra_raw_policy_info',
 'ipod_policy_mga_cape','ipod_xmga_vave_dwelling_fire_raw_policy_info','pl_schedule',
 'inspection__c','vrna__pl_schedule__c','insurance_policy')
 AND match(lower(name),'roof|attest|policy|quote|dwelling|property|created|issued|effective|received|review|ordered|modified|locator|deleted|^id$'))
 OR match(lower(name),'roof.*replac|roof.*year|roof.*material|roof.*attest|attest.*roof')
)
ORDER BY database,table,name;
