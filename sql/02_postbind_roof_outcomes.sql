-- 02_postbind_roof_outcomes.sql  (Metabase db 235, ClickHouse; read-only)
-- Phase 2 extract: post-bind roof outcomes joined to the bind-time score.
-- Export as CSV and feed to:  python3 -m roof_dial overlay outcomes.csv --window 90
--
-- Runs TODAY against the frozen 8/16 snapshots (creations Jan-May 2026, three
-- cohort slices only). Phase 2 proper rebuilds the cohort for ALL April+ binds
-- age 80+ using the documented recipe in
-- ~/mockups/damr-postbind-uarnoe/ANALYSIS-2026-08-16.md
-- (the event machinery is population-agnostic; only the cohort WHERE changes).
--
-- Verified 2026-08-20: joins are 100% (every event policy has a new-business
-- row); the roof-add event is e_prev='' -> e_cur='selected' on
-- e_col='roof_surfacing_exclusion'; the NOC sub-reason string is exactly
-- 'Condition - Roof'. Trap: 9 roof-add events carry
-- f_ev_class='attribute_correction', so identify roof adds through the detail
-- table, never through f_ev_class alone.
-- Era note: scores exist on April+ binds only (Jan 0% / Feb 0% / Mar 10% /
-- Apr 89% / May 99% / Jun-Jul 100%). Quote scored-rates on the April+ era.

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
    -- underwriter adds the exclusion after bind (the corrective NOE lane)
    SELECT f.f_policy_id AS policy_id, 'roof_noe' AS kind,
           f.f_days_since_bind AS days_since_bind, f.f_actor_class AS actor_class,
           f.f_cohort AS cohort, toStartOfMonth(f.f_bind_ts) AS bind_month
    FROM dbt_dev.damr_uarnoe_final_20260816 AS f
    INNER JOIN roof_add r ON r.e_quote_id = f.f_ev_quote_id
    WHERE f.f_actor_class = 'uw'

    UNION ALL
    -- inspection cancellation with the roof sub-reason (the NOC lane)
    SELECT f.f_policy_id, 'roof_noc',
           f.f_days_since_bind, f.f_actor_class, f.f_cohort, toStartOfMonth(f.f_bind_ts)
    FROM dbt_dev.damr_uarnoe_final_20260816 AS f
    WHERE f.f_ev_class = 'cancellation'
      AND f.f_canc_reason = 'Inspection'
      AND f.f_uw_canc_reason = 'Condition - Roof'

    UNION ALL
    -- the exclusion comes OFF after bind (the pushback lane; tiny so far)
    SELECT f.f_policy_id, 'rse_removed',
           f.f_days_since_bind, f.f_actor_class, f.f_cohort, toStartOfMonth(f.f_bind_ts)
    FROM dbt_dev.damr_uarnoe_final_20260816 AS f
    INNER JOIN roof_remove r ON r.e_quote_id = f.f_ev_quote_id
),
nb AS (
    -- bind-time state, aggregated over dwellings (one NB version per policy)
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
