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
--
-- KNOWN LIMITS (2026-08-21 review; see RESULTS-2026-08-20.md "Corrections"):
--   1. SURVIVOR SAMPLE. quote_status = 'Issued' keeps bound policies only, but
--      the exclusion is applied BEFORE bind and can change whether a quote
--      binds. This describes bound survivors under historical underwriting,
--      not the traffic a wider rule would meet, so monthly over-apply volume
--      is likely understated. The decision-grade version builds the cohort at
--      score/decision time over ALL eligible quotes and keeps bind/non-bind
--      (and time to bind) as an outcome.
--   2. AGE AND WINDOW DO NOT MATCH THE MEMO. This file is age >= 80 with an
--      April 1 start and no end date; the memo's primary Phase 1 curve is
--      101+ over May 1 - Aug 15. Uncomment the age and date bounds to
--      reproduce it, and pin the model version (see the optional cuts below).
--   3. MODEL VERSION IS NOT PINNED, so the curve pools v1.1.x (which scores
--      the book 5-10 points hot) with v1.2.0. Pooling is NOT uniformly a
--      conservative floor: at bar 80 it moves capture 58.0% -> 60.7% while
--      moving over-per-catch 0.87 -> 1.10. Any quoted bar must be priced on
--      v1.2.0 alone.
--   4. uw_reviewed IS NOT AN OBSERVED ROOF REVIEW. It means "an alert required
--      a look at this quote". It cannot carry "the underwriter looked at the
--      roof and disagreed" without roof-specific review/action evidence.

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
    -- verified 2026-08-20: the column is alert_category (not category),
    -- and requires_uw_review is a Bool that needs the toUInt8 cast
    SELECT quote_id, max(toUInt8(requires_uw_review)) AS uw_reviewed
    FROM dbt_upc.uw_alerts_per_quote
    WHERE alert_category NOT IN ('DATA_SAFEGUARD', 'VALIDATION', 'SHOWSTOPPER', 'SYSTEM_ERROR')
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
