-- RUN 2026-09-23, completed, 12 aggregate/schema rows. Metabase db 235; SELECT only.
-- Purpose: determine whether existing Socotra fields contain the proposed full-roof-replacement-in 20 years statement.
-- Expected: unknown. A generic underwriting attestation or general remodel is not the proposed question.
-- Only aggregate pattern classes leave the database; no statement/answer text or entity identifiers are returned.
-- Pattern candidates need wording and scope confirmation; the regex is not a semantic validation.
-- This is an unwindowed source census until verified quote/policy linkage and source timestamps are mapped.
WITH a AS (
 SELECT 'quote' AS source,underwriting_attestation_statement AS statement,underwriting_attestation_answer AS answer
 FROM dbt.socotra_raw_quote_info
 UNION ALL
 SELECT 'policy' AS source,underwriting_attestation_statement AS statement,underwriting_attestation_answer AS answer
 FROM dbt.socotra_raw_policy_info
), classes AS (
 SELECT source,
 multiIf(trimBoth(statement)='','blank',
 match(lower(statement),'roof') AND match(lower(statement),'replac')
 AND match(lower(statement),'full|entire|complete') AND match(lower(statement),'(^|[^0-9])20([^0-9]|$)|twenty'),'roof_full_replacement_20_pattern_candidate',
 match(lower(statement),'roof') AND match(lower(statement),'replac'),'other_roof_replacement',
 match(lower(statement),'roof'),'other_roof',match(lower(statement),'remodel|renovat'),'general_remodel_renovation',
 'other_attestation') AS statement_class,
 multiIf(trimBoth(answer)='','blank',lower(trimBoth(answer)) IN ('yes','true','1'),'yes_like',
 lower(trimBoth(answer)) IN ('no','false','0'),'no_like','other_nonempty') AS answer_class
 FROM a
)
SELECT source,statement_class,answer_class,count() AS source_rows
FROM classes GROUP BY source,statement_class,answer_class
ORDER BY source,statement_class,answer_class;
