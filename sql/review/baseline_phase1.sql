-- RUN 2026-09-23. Completed SELECTs; returned rows per statement: 360.
-- Purpose: Reproduce fine-bar counts, v1.2.0 sensitivity, younger bands, launch states and April sensitivity.
-- Claim IDs: R2 R3 R4 S4 S5 S6 S17 S30 RS2 RS3 RS7 RS8 RS10 RS12 A16 A21
-- Expected if the first read is right: May 1-Aug 15 pooled 101+ at 85/83/80: catches 516/557/618 of 1018 hand; over 429/528/682 of 4404 none. v1.2.0 bar80 58.0% and 0.87 require fresh counts.
-- Output is aggregate only. Live current rows cannot restore an earlier warehouse snapshot.

WITH base AS (
 SELECT policy_id, quote_id, dwelling_id, pol_created_timestamp AS created,
        pol_prop_state AS state, pol_prop_steadily_roof_condition_score_model_version AS model_version, pol_prop_steadily_roof_condition_score_condition_score AS score,
        2026 - pol_prop_year_built AS age, multiIf(prop_cov_roof_surfacing_exclusion = 'selected' AND pol_ff_automated_roof_exclusion = 'yes' AND pol_prop_steadily_roof_condition_score_decision = 'exclude', 'auto', prop_cov_roof_surfacing_exclusion = 'selected', 'hand', 'none') AS lane
 FROM dbt.ipod_standard_mga_raw_policy_info
 WHERE quote_type='NewBusiness' AND quote_status='Issued'
   AND pol_created_timestamp >= toDateTime('2026-04-01 00:00:00')
   AND pol_created_timestamp < toDateTime('2026-08-16 00:00:00')
   AND pol_prop_year_built > 1700 AND 2026 - pol_prop_year_built >= 80
), expanded AS (
 SELECT *, arrayJoin(['pooled', 'v1.2.0']) AS version_cut,
        arrayJoin(['April 1-August 15', 'May 1-August 15']) AS window_cut,
        arrayJoin(['all', if(state IN ('AZ','NJ','PA','TN','NC','TX','CA'), 'launch', 'nonlaunch')]) AS state_cut,
        multiIf(age >=101, '101+', age >=91, '91-100', '80-90') AS age_band,
        arrayJoin([55,60,65,70,75,80,83,85,90,95]) AS bar
 FROM base
 WHERE (version_cut='pooled' OR model_version='v1.2.0')
   AND (window_cut='April 1-August 15' OR created >= toDateTime('2026-05-01'))
)
SELECT window_cut, version_cut, state_cut, age_band, bar,
       countIf(lane='hand') AS hand_n, countIf(lane='none') AS none_n,
       countIf(lane='auto') AS auto_n,
       countIf(lane='hand' AND score IS NULL) AS hand_unscored,
       countIf(lane='none' AND score IS NULL) AS none_unscored,
       countIf(lane='hand' AND score>=bar) AS catches,
       countIf(lane='none' AND score>=bar) AS over_applies,
       100.0*catches/nullIf(hand_n,0) AS capture_pct,
       1.0*over_applies/nullIf(catches,0) AS running_over_per_catch,
       quantilesExactIf(0.25,0.5,0.75,0.9)(score, lane='hand' AND score IS NOT NULL) AS hand_quantiles,
       quantilesExactIf(0.25,0.5,0.75,0.9)(score, lane='none' AND score IS NOT NULL) AS none_quantiles,
       uniqExact(policy_id) AS policy_clusters
FROM expanded GROUP BY window_cut, version_cut, state_cut, age_band, bar
ORDER BY window_cut, version_cut, state_cut, age_band, bar;
-- This is an issued-current-row reproduction, NOT decision-time attribution or eligibility.
-- 2026-year_built is the original Phase 1 home-age definition. States/forms are not excluded
-- here because the historical counts included them. The decision-grade rebuild must apply
-- verified form eligibility and event-sourced application labels after schema discovery.
-- Compare starts and state cuts descriptively. This does not prove automation skimmed roofs.
