-- RUN 2026-09-23. Completed SELECTs; returned rows per statement: 12.
-- Purpose: Re-derive pooled/v1.2.0 P80 on current quote traffic and bound homes; explicit missing/auto handling.
-- Claim IDs: RS6 S30 A39
-- Expected if the first read is right: Legacy pooled bound 101+ P80=83 is a hypothesis, not certified. Decision-time eligible P80 cannot be recovered from the supplied current-row schema.
-- Output is aggregate only. Live current rows cannot restore an earlier warehouse snapshot.

WITH homes AS (
 SELECT quote_id, dwelling_id, pol_prop_steadily_roof_condition_score_condition_score AS score, pol_prop_steadily_roof_condition_score_model_version AS version,
        quote_status='Issued' AS issued, multiIf(prop_cov_roof_surfacing_exclusion = 'selected' AND pol_ff_automated_roof_exclusion = 'yes' AND pol_prop_steadily_roof_condition_score_decision = 'exclude', 'auto', prop_cov_roof_surfacing_exclusion = 'selected', 'hand', 'none') AS lane
 FROM dbt.ipod_standard_mga_raw_policy_info
 WHERE quote_type='NewBusiness' AND pol_created_timestamp>=toDateTime('2026-05-01')
 AND pol_created_timestamp<toDateTime('2026-08-16')
 AND pol_prop_year_built>1700 AND 2026-pol_prop_year_built>=101
), rows_ AS (
 SELECT 'home' AS grain, 'all quotes current row' AS population, score, issued, version, lane FROM homes
 UNION ALL
 SELECT 'home', 'bound current row', score, issued, version, lane FROM homes WHERE issued
 UNION ALL
 SELECT 'quote max of 101+ homes', 'all quotes current row', max(score), max(issued),
        if(countIf(version!='v1.2.0')=0,'v1.2.0','mixed_or_other'),
        if(countIf(lane='auto')>0,'auto','other')
 FROM homes GROUP BY quote_id
), expanded AS (
 SELECT *, arrayJoin(['pooled','v1.2.0']) AS version_cut,
        arrayJoin(['include_auto','drop_auto']) AS auto_handling
 FROM rows_ WHERE (version_cut='pooled' OR version='v1.2.0') AND (auto_handling='include_auto' OR lane!='auto')
)
SELECT grain, population, version_cut, auto_handling, count() AS total_units,
       countIf(score IS NULL) AS unscored_units, countIf(score IS NOT NULL) AS scored_units,
       quantileExactIf(0.8)(score,score IS NOT NULL) AS p80_scored_only,
       countIf(score>=83) AS units_ge83,
       100.0*units_ge83/nullIf(scored_units,0) AS pct_scored_ge83,
       100.0*units_ge83/nullIf(total_units,0) AS pct_all_ge83
FROM expanded GROUP BY grain,population,version_cut,auto_handling;
-- Gate: current rows are NOT decision-time versions, and form eligibility is unknown.
-- This proxy is only a direction/grain sensitivity. baseline_schema_dependencies.sql must
-- locate verified version history and form availability before any eligible traffic claim.
-- Auto homes are explicit, unscored homes are counted separately and excluded from quantile.
