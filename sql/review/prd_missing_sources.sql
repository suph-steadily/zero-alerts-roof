-- Purpose: discover sources needed for age-alert abandonment, action ranking, attestation and letters.
-- Claims P1,P2,P29,P31,A8,A9,A10,A44,A46,A47. Expected: no attestation measurement yet;
-- PRD's 70-80%, 115-175,25/month,~half and one-day causal claims lack checked-in support.
-- RUN 2026-09-23, 237 schema-metadata rows, review/root_runs.json.
-- Exact discovery SELECT. No event payloads, IDs or person data are output.
-- Not a substitute for a measurement query: schema mappings are a blocked dependency.
SELECT database,table,name,type
FROM system.columns
WHERE database IN ('dbt','dbt_upc','raw_pg_eventstore','tap_veruna')
 AND (match(lower(name),'attest|roof.*year|permit|letter|notice|inspection|audit|actor|alert_category')
      OR match(lower(table),'attest|audit|letter|notice|inspection'))
ORDER BY database,table,name;
