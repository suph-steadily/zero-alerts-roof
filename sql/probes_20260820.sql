-- probes_20260820.sql  (Metabase db 235, ClickHouse; all read-only)
-- The verification queries behind every headline number in the scope and the
-- shared page. Run any of them as-is to check the claim it is labeled with.
-- Window used throughout: pol_created_timestamp 2026-05-01 .. 2026-08-15
-- (Aug is a partial month and right-censored: recent drafts still convert).

-- ============================================================================
-- CLAIM: "5.5% automation / 94.5% hand-applied" and "go-forward pool 80-120/mo"
-- (8/21 note: 80-120 is the May-Jul flag-on lane; the post-expansion Aug floor
--  is ~174/mo in 101+ - see RESULTS "Texas and go-forward volumes")
-- (provenance of the exclusion on bound 101+ and 91-100 homes, by month)
-- ============================================================================
SELECT toStartOfMonth(pol_created_timestamp) AS mo,
       multiIf(2026 - pol_prop_year_built >= 101, '101+', '91-100') AS age_band,
       count() AS excl_dwellings,
       uniqExact(quote_id) AS excl_quotes,
       countIf(pol_ff_automated_roof_exclusion = 'yes'
               AND pol_prop_steadily_roof_condition_score_decision = 'exclude') AS auto_applied,
       countIf(pol_ff_automated_roof_exclusion = 'yes'
               AND pol_prop_steadily_roof_condition_score_decision != 'exclude') AS hand_flag_on,
       countIf(pol_ff_automated_roof_exclusion != 'yes') AS hand_flag_off
FROM dbt.ipod_standard_mga_raw_policy_info
WHERE quote_type = 'NewBusiness' AND quote_status = 'Issued'
  AND pol_created_timestamp >= toDateTime('2026-05-01 00:00:00')
  AND pol_created_timestamp <  toDateTime('2026-08-16 00:00:00')
  AND prop_cov_roof_surfacing_exclusion = 'selected'
  AND pol_prop_year_built > 1700
  AND 2026 - pol_prop_year_built >= 91
GROUP BY mo, age_band ORDER BY mo, age_band;
-- Verified result (101+ dwelling totals): May 320 (15/100/205) . Jun 375 (25/112/238)
-- . Jul 293 (17/117/159) . Aug 1-15 89 (2/83/4). Window: 59 auto vs 1,018 hand.

-- ============================================================================
-- CLAIM: the preview curve bands ("36.1% capture at 91+ ...", median 85 vs 45)
-- (score distribution by group on bound 101+; feed the counts to the tool)
-- ============================================================================
SELECT multiIf(prop_cov_roof_surfacing_exclusion = 'selected'
               AND pol_ff_automated_roof_exclusion = 'yes'
               AND pol_prop_steadily_roof_condition_score_decision = 'exclude', 'auto',
               prop_cov_roof_surfacing_exclusion = 'selected', 'hand', 'none') AS grp,
       multiIf(pol_prop_steadily_roof_condition_score_condition_score IS NULL, 'null',
               pol_prop_steadily_roof_condition_score_condition_score <= 50, '<=50',
               pol_prop_steadily_roof_condition_score_condition_score <= 60, '51-60',
               pol_prop_steadily_roof_condition_score_condition_score <= 70, '61-70',
               pol_prop_steadily_roof_condition_score_condition_score <= 80, '71-80',
               pol_prop_steadily_roof_condition_score_condition_score <= 90, '81-90',
               '91-100') AS score_band,
       count() AS dwellings
FROM dbt.ipod_standard_mga_raw_policy_info
WHERE quote_type = 'NewBusiness' AND quote_status = 'Issued'
  AND pol_created_timestamp >= toDateTime('2026-05-01 00:00:00')
  AND pol_created_timestamp <  toDateTime('2026-08-16 00:00:00')
  AND pol_prop_year_built > 1700
  AND 2026 - pol_prop_year_built >= 101
GROUP BY grp, score_band ORDER BY grp, score_band;
-- Verified result lives in examples/bound_101plus_bands_20260820.csv (pinned by tests).
-- Quantiles: swap the multiIf for
--   quantiles(0.25, 0.5, 0.75, 0.9)(assumeNotNull(pol_prop_steadily_roof_condition_score_condition_score))
-- -> auto 92.5/95/96/98 . hand 71/85/94/97 . none 28/45/70/84.

-- ============================================================================
-- CLAIM: "99.6% of bound quotes are scored" and the April score cliff
-- (quote-level coverage by bound status and age band)
-- ============================================================================
WITH per_quote AS (
    SELECT quote_id,
           max(quote_issued_timestamp IS NOT NULL) AS issued,
           max(pol_prop_year_built > 1700) AS has_valid_yb,
           maxIf(2026 - pol_prop_year_built, pol_prop_year_built > 1700) AS age,
           max(pol_prop_steadily_roof_condition_score_condition_score IS NOT NULL) AS has_score
    FROM dbt.ipod_standard_mga_raw_policy_info
    WHERE quote_type = 'NewBusiness'
      AND pol_created_timestamp >= toDateTime('2026-05-01 00:00:00')
      AND pol_created_timestamp <  toDateTime('2026-08-16 00:00:00')
    GROUP BY quote_id
)
SELECT issued,
       multiIf(has_valid_yb = 0, 'yb_missing', age >= 101, '101+',
               age >= 91, '91-100', age >= 80, '80-90', '<80') AS age_band,
       count() AS quotes, sum(has_score) AS scored
FROM per_quote GROUP BY issued, age_band ORDER BY issued, age_band;
-- Verified: issued quotes scored 99.4-99.8% in every band. For the cliff, run the
-- same shape month by month from January: Jan 0% . Feb 0% . Mar 10% . Apr 89% .
-- May 99% . Jun-Jul 100% (score computation shipped mid-March).

-- ============================================================================
-- CLAIM: "the live exclude decision is not a pure score cut" (excludes span 1-97)
-- ============================================================================
SELECT pol_prop_steadily_roof_condition_score_model_version AS model_ver,
       pol_prop_steadily_roof_condition_score_decision AS decision,
       count() AS rows_,
       min(pol_prop_steadily_roof_condition_score_condition_score) AS min_score,
       max(pol_prop_steadily_roof_condition_score_condition_score) AS max_score
FROM dbt.ipod_standard_mga_raw_policy_info
WHERE quote_type = 'NewBusiness'
  AND pol_created_timestamp >= toDateTime('2026-05-01 00:00:00')
  AND pol_created_timestamp <  toDateTime('2026-08-16 00:00:00')
GROUP BY model_ver, decision ORDER BY model_ver, decision;
-- Verified: decision values are '', 'pass', 'alert', 'exclude'; v1.2.0 'exclude'
-- spans scores 1-97 (and 'pass' also reaches 97), so score alone does not
-- reproduce the production rule. Actual auto-fires still cluster 90+.

-- ============================================================================
-- CLAIM: "69% of post-bind roof NOEs had a bind score of 60+" (harm overlay)
-- (roof-added UW endorsements within 90d joined to the bind-time score;
--  runs on the frozen 8/16 snapshots)
-- ============================================================================
WITH roof_add AS (
    SELECT DISTINCT e_quote_id FROM dbt_dev.damr_uarnoe_evdetail_20260816
    WHERE e_col = 'roof_surfacing_exclusion' AND e_prev = '' AND e_cur = 'selected'
),
ev AS (
    SELECT f_policy_id, min(f_bind_ts) AS bind_ts
    FROM dbt_dev.damr_uarnoe_final_20260816 f
    INNER JOIN roof_add r ON r.e_quote_id = f.f_ev_quote_id
    WHERE f_actor_class = 'uw' AND f_days_since_bind BETWEEN 0 AND 90
    GROUP BY f_policy_id
),
nb AS (
    SELECT policy_id,
           max(pol_prop_steadily_roof_condition_score_condition_score) AS score
    FROM dbt.ipod_standard_mga_raw_policy_info
    WHERE quote_type = 'NewBusiness'
      AND policy_id IN (SELECT f_policy_id FROM ev)
    GROUP BY policy_id
)
SELECT count() AS policies,
       countIf(nb.score IS NOT NULL) AS scored,
       countIf(nb.score >= 60) AS ge60, countIf(nb.score >= 70) AS ge70,
       countIf(nb.score >= 80) AS ge80, countIf(nb.score >= 90) AS ge90,
       countIf(nb.score >= 60 AND toDate(ev.bind_ts) >= toDate('2026-04-01')) AS ge60_apr_plus
FROM ev LEFT JOIN nb ON nb.policy_id = ev.f_policy_id;
-- Verified: 1,237 policies, 641 scored overall (era artifact: Jan-Mar binds are
-- unscored); April+ binds are 94.3% scored, 434 of 633 at 60+ (68.6%).

-- ============================================================================
-- CLAIM: "72.6% of Condition - Roof NOCs (0-90 day window) had a bind score of 60+"
-- (corrected 8/21: the original probe omitted the 0-90 day filter and read
--  80 of 110 = 72.7%; with the filter, matching the Phase 2 window, it is
--  77 of 106 = 72.6%. SCOPE.md carries the correction.)
-- ============================================================================
WITH ev AS (
    SELECT f_policy_id, min(f_days_since_bind) AS d, min(f_bind_ts) AS bind_ts
    FROM dbt_dev.damr_uarnoe_final_20260816
    WHERE f_ev_class = 'cancellation' AND f_canc_reason = 'Inspection'
      AND f_uw_canc_reason = 'Condition - Roof'
      AND f_days_since_bind BETWEEN 0 AND 90
    GROUP BY f_policy_id
),
nb AS (
    SELECT policy_id,
           max(pol_prop_steadily_roof_condition_score_condition_score) AS score
    FROM dbt.ipod_standard_mga_raw_policy_info
    WHERE quote_type = 'NewBusiness'
      AND policy_id IN (SELECT f_policy_id FROM ev)
    GROUP BY policy_id
)
SELECT count() AS policies, countIf(nb.score IS NOT NULL) AS scored,
       countIf(nb.score >= 60) AS ge60, countIf(nb.score >= 80) AS ge80,
       countIf(nb.score >= 60 AND toDate(ev.bind_ts) >= toDate('2026-04-01')) AS ge60_apr_plus
FROM ev LEFT JOIN nb ON nb.policy_id = ev.f_policy_id;
-- Verified with the 0-90d filter: April+ binds 77 of 106 at 60+ (72.6%).
-- (The unfiltered run read 190 policies / 80 of 110 at 60+; kept for the record.)

-- ============================================================================
-- CLAIM: "the pushback lane is unmeasured (n=1 on auto applies)"
-- (post-bind removals of the exclusion, split by what was at bind)
-- ============================================================================
WITH roof_remove AS (
    SELECT DISTINCT e_quote_id FROM dbt_dev.damr_uarnoe_evdetail_20260816
    WHERE e_col = 'roof_surfacing_exclusion' AND e_prev = 'selected' AND e_cur = ''
)
SELECT f.f_actor_class, count() AS events
FROM dbt_dev.damr_uarnoe_final_20260816 f
INNER JOIN roof_remove r ON r.e_quote_id = f.f_ev_quote_id
GROUP BY f.f_actor_class;
-- Verified: 64 events / 63 policies (uw 28, agent 22, cx 9, other 5); only 9
-- removals undid a BIND-TIME exclusion, and just 1 of those was auto-applied.
-- The spring waves have no runway yet: re-pull around October.

-- ============================================================================
-- RECORDED DEAD END: dbt_data_science.fct_roof_exclusion
-- ============================================================================
-- CAPE-vendor-era feasibility study (has_cape_data=1 on all 562,744 rows;
-- cape_roof_condition_rating is dirty: '0','2','-1', raw JSON; epoch-zero dates).
-- No Steadily score, no decision, no flag, no who-applied-it. Salvage value:
-- roof_uw_action_count as an independent "a UW touched this roof" cross-check.

-- ============================================================================
-- CLAIM (added same day): "homes with the exclusion at bind do not get
-- roof-cancelled" and "today's setting caught 0 of the 106 roof NOCs"
-- (April+ cohort binds; roof-NOC rate by bind score band x exclusion at bind)
-- ============================================================================
WITH coh AS (
    SELECT o_policy_id AS policy_id
    FROM dbt_dev.damr_uarnoe_cohort_20260816
    WHERE o_bind_ts >= toDateTime64('2026-04-01 00:00:00', 6)
    GROUP BY o_policy_id
),
noc AS (
    SELECT DISTINCT f_policy_id
    FROM dbt_dev.damr_uarnoe_final_20260816
    WHERE f_ev_class = 'cancellation' AND f_canc_reason = 'Inspection'
      AND f_uw_canc_reason = 'Condition - Roof' AND f_days_since_bind BETWEEN 0 AND 90
),
nb AS (
    SELECT policy_id,
           max(pol_prop_steadily_roof_condition_score_condition_score) AS score,
           max(if(prop_cov_roof_surfacing_exclusion = 'selected', 1, 0)) AS rse
    FROM dbt.ipod_standard_mga_raw_policy_info
    WHERE quote_type = 'NewBusiness' AND quote_status = 'Issued'
      AND policy_id IN (SELECT policy_id FROM coh)
    GROUP BY policy_id
)
SELECT multiIf(score IS NULL, 'unscored', score >= 90, '90+',
               score >= 83, '83-89', 'below 83') AS score_band,
       rse AS exclusion_at_bind,
       count() AS bound_policies,
       countIf(policy_id IN (SELECT f_policy_id FROM noc)) AS roof_nocs
FROM nb GROUP BY score_band, exclusion_at_bind ORDER BY score_band, exclusion_at_bind;
-- Verified: 90+ with exclusion 0/214 vs without 21/1,167 (1.8 per 100);
-- 83-89: 1/58 vs 16/785. Companion cut on the 106 roof NOCs themselves:
-- model decision said 'exclude' on 0 of 106 (even the 12 scoring 95+);
-- only 1 of 106 carried the exclusion at bind (hand-applied, 83-89 band).
