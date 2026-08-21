-- 03_overapply_disposition.sql  (Metabase db 235, ClickHouse; read-only)
-- Phase 3: classify the over-applies at one candidate bar.
-- An over-apply = a bound left-alone dwelling scoring at or above the bar.
-- Classes: late catch (drew a roof NOE or NOC within the window anyway),
-- true disagreement (an underwriter reviewed and left the roof alone),
-- presumed false positive (never reviewed, clean at 90 days).
--
-- The same classification is available offline via
--   python3 -m roof_dial disposition bound_book.csv outcomes.csv --bar 80
-- using the extracts from 01 and 02; this SQL is the one-shot warehouse
-- version. Snapshot-based for now, same rebuild note as 02.
-- Set the bar here:
--   {bar} -> e.g. 80
--
-- ############################################################################
-- WITHDRAWN 2026-08-21 - DO NOT QUOTE THE OUTPUT OF THIS FILE.
-- The negative label is invalid, not merely incomplete. Harm comes only from
-- the frozen three-slice snapshot (outcome_policies below), but the `bound`
-- denominator is EVERY issued age-80+ policy from April onward, with no
-- snapshot-cohort membership and no 90-day maturity requirement. The final
-- LEFT JOIN therefore classifies as clean:
--   * every policy outside the outcome census, and
--   * every policy still inside its 90-day runway.
-- Both land in presumed_false_positive, which is why that share came out at
-- 72-75%. Calling it a "ceiling" understated the problem.
--
-- Second defect: uw_reviewed means "an alert required a look at this quote",
-- so the true_disagreement class cannot be read as "an underwriter looked at
-- the roof and chose to leave it".
--
-- To make this quotable: join every candidate to an explicit outcome-cohort
-- manifest plus a follow-up end date, and classify each row as one of
--   harm_observed | mature_clean | right_censored | outside_outcome_census.
-- Only mature, in-census policies may enter a false-positive denominator.
-- roof_dial/overlay.py has the same gap (no outcome-observation eligibility).
-- ############################################################################

WITH
outcome_policies AS (
    SELECT DISTINCT f.f_policy_id AS policy_id
    FROM dbt_dev.damr_uarnoe_final_20260816 AS f
    LEFT JOIN dbt_dev.damr_uarnoe_evdetail_20260816 AS d ON d.e_quote_id = f.f_ev_quote_id
    WHERE f.f_days_since_bind BETWEEN 0 AND 90
      AND (
            (d.e_col = 'roof_surfacing_exclusion' AND d.e_prev = '' AND d.e_cur = 'selected'
             AND f.f_actor_class = 'uw')
         OR (f.f_ev_class = 'cancellation' AND f.f_canc_reason = 'Inspection'
             AND f.f_uw_canc_reason = 'Condition - Roof')
          )
),
bound AS (
    SELECT p.policy_id,
           max(p.pol_prop_steadily_roof_condition_score_condition_score) AS score,
           max(if(p.prop_cov_roof_surfacing_exclusion = 'selected', 1, 0)) AS rse_selected,
           max(coalesce(toUInt8(a.uw_reviewed), 0)) AS uw_reviewed
    FROM dbt.ipod_standard_mga_raw_policy_info AS p
    LEFT JOIN
    (
        -- verified 2026-08-20: the column is alert_category (not category),
        -- and requires_uw_review is a Bool that needs the toUInt8 cast
        SELECT quote_id, max(toUInt8(requires_uw_review)) AS uw_reviewed
        FROM dbt_upc.uw_alerts_per_quote
        WHERE alert_category NOT IN ('DATA_SAFEGUARD', 'VALIDATION', 'SHOWSTOPPER', 'SYSTEM_ERROR')
        GROUP BY quote_id
    ) AS a ON a.quote_id = p.quote_id
    WHERE p.quote_type = 'NewBusiness'
      AND p.quote_status = 'Issued'
      AND p.pol_created_timestamp >= toDateTime('2026-04-01 00:00:00')
      AND p.pol_prop_year_built > 1700
      AND 2026 - p.pol_prop_year_built >= 80
    GROUP BY p.policy_id
)
SELECT
    multiIf(o.policy_id != '',   'late_catch',
            b.uw_reviewed = 1,   'true_disagreement',
            'presumed_false_positive')  AS disposition,
    count()                             AS policies
FROM bound AS b
LEFT JOIN outcome_policies AS o ON o.policy_id = b.policy_id
WHERE b.rse_selected = 0        -- left alone at bind
  AND b.score >= {bar}          -- the candidate bar
GROUP BY disposition
