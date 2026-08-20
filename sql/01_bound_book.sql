-- 01_bound_book.sql  (Metabase db 235, ClickHouse; read-only)
-- Phase 1 extract: one row per bound new-business DWELLING, age 80+, score era.
-- Export as CSV and feed to:  python3 -m roof_dial sweep bound_book.csv --months <window months>
--
-- Verified 2026-08-20: all column names checked against the live table; score
-- coverage on bound quotes 99.6%; 'Issued' status is identical to
-- quote_issued_timestamp non-null. Traps honored below: pol_created_timestamp
-- (never policy_original_created_timestamp), exclusion tested = 'selected',
-- year_built guarded > 1700.
--
-- uw_reviewed comes from the alert table the 8/16 cohort build used; it marks
-- "an underwriter was required to look at this quote" and powers the
-- over-apply disposition (true disagreement vs never reviewed).

SELECT
    p.quote_id                                                        AS quote_id,
    p.policy_id                                                       AS policy_id,
    p.dwelling_id                                                     AS dwelling_id,
    p.pol_prop_state                                                  AS state,
    toStartOfMonth(p.pol_created_timestamp)                           AS bind_month,
    p.pol_prop_year_built                                             AS year_built,
    2026 - p.pol_prop_year_built                                      AS age,
    multiIf(2026 - p.pol_prop_year_built >= 101, '101+',
            2026 - p.pol_prop_year_built >= 91,  '91-100',
            '80-90')                                                  AS age_band,
    p.pol_prop_steadily_roof_condition_score_condition_score          AS score,
    p.pol_prop_steadily_roof_condition_score_decision                 AS decision,
    p.pol_prop_steadily_roof_condition_score_model_version            AS model_version,
    p.pol_ff_automated_roof_exclusion                                 AS flag,
    if(p.prop_cov_roof_surfacing_exclusion = 'selected', 1, 0)        AS rse_selected,
    coalesce(a.uw_reviewed, 0)                                        AS uw_reviewed
FROM dbt.ipod_standard_mga_raw_policy_info AS p
LEFT JOIN
(
    -- substantive-alert basis from the 8/16 cohort recipe
    SELECT quote_id, max(requires_uw_review) AS uw_reviewed
    FROM dbt_upc.uw_alerts_per_quote
    WHERE category NOT IN ('DATA_SAFEGUARD', 'VALIDATION', 'SHOWSTOPPER', 'SYSTEM_ERROR')
    GROUP BY quote_id
) AS a ON a.quote_id = p.quote_id
WHERE p.quote_type = 'NewBusiness'
  AND p.quote_status = 'Issued'
  AND p.pol_created_timestamp >= toDateTime('2026-04-01 00:00:00')   -- score era starts April 2026
  AND p.pol_prop_year_built > 1700
  AND 2026 - p.pol_prop_year_built >= 80
-- Optional cuts for later phases:
--   AND p.pol_prop_state = 'TX'                       -- Texas-first read
--   AND p.pol_prop_steadily_roof_condition_score_model_version = 'v1.2.0'   -- pin the model
