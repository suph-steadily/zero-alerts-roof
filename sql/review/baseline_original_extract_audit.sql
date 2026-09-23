-- RUN 2026-09-23. Completed SELECTs; returned rows per statement: 1, 3.
-- Purpose: run original open-ended extracts safely, returning counts only.
-- Claim IDs: R3 Q1 Q2 A19 A20.
-- Expected: original01 is open-ended80+; original02 event count exceeds policy count.
SELECT count() AS home_rows,uniqExact(tuple(policy_id,dwelling_id)) AS home_keys,uniqExact(quote_id) AS quotes, countIf(score IS NULL) AS unscored FROM (
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
);
SELECT kind,count() AS event_rows,uniqExact(policy_id) AS policies,countIf(bind_score IS NOT NULL) AS scored_event_rows,uniqExactIf(policy_id,days_since_bind BETWEEN 0 AND 90 AND bind_month>=toDate('2026-04-01')) AS april_90_policies FROM (
WITH
roof_add AS (
    SELECT DISTINCT e_quote_id
    FROM dbt_dev.damr_uarnoe_evdetail_20260816
    WHERE e_col = 'roof_surfacing_exclusion' AND e_prev = '' AND e_cur = 'selected'
),
roof_remove AS (
    SELECT DISTINCT e_quote_id
    FROM dbt_dev.damr_uarnoe_evdetail_20260816
    WHERE e_col = 'roof_surfacing_exclusion' AND e_prev = 'selected' AND e_cur = ''
),
events AS (
    SELECT f.f_policy_id AS policy_id, 'roof_noe' AS kind,
           f.f_days_since_bind AS days_since_bind, f.f_actor_class AS actor_class,
           f.f_cohort AS cohort, toStartOfMonth(f.f_bind_ts) AS bind_month
    FROM dbt_dev.damr_uarnoe_final_20260816 AS f
    INNER JOIN roof_add r ON r.e_quote_id = f.f_ev_quote_id
    WHERE f.f_actor_class = 'uw'

    UNION ALL
    SELECT f.f_policy_id, 'roof_noc',
           f.f_days_since_bind, f.f_actor_class, f.f_cohort, toStartOfMonth(f.f_bind_ts)
    FROM dbt_dev.damr_uarnoe_final_20260816 AS f
    WHERE f.f_ev_class = 'cancellation'
      AND f.f_canc_reason = 'Inspection'
      AND f.f_uw_canc_reason = 'Condition - Roof'

    UNION ALL
    SELECT f.f_policy_id, 'rse_removed',
           f.f_days_since_bind, f.f_actor_class, f.f_cohort, toStartOfMonth(f.f_bind_ts)
    FROM dbt_dev.damr_uarnoe_final_20260816 AS f
    INNER JOIN roof_remove r ON r.e_quote_id = f.f_ev_quote_id
),
nb AS (
    SELECT policy_id,
           max(pol_prop_steadily_roof_condition_score_condition_score) AS bind_score,
           max(if(prop_cov_roof_surfacing_exclusion = 'selected', 1, 0)) AS bind_rse_selected,
           max(pol_ff_automated_roof_exclusion)                          AS bind_flag,
           max(pol_prop_steadily_roof_condition_score_decision)          AS bind_decision
    FROM dbt.ipod_standard_mga_raw_policy_info
    WHERE quote_type = 'NewBusiness'
      AND policy_id IN (SELECT policy_id FROM events)
    GROUP BY policy_id
)
SELECT e.policy_id, e.kind, e.days_since_bind, e.actor_class, e.cohort, e.bind_month,
       nb.bind_score, nb.bind_rse_selected, nb.bind_flag, nb.bind_decision
FROM events AS e
LEFT JOIN nb ON nb.policy_id = e.policy_id
) GROUP BY kind;
