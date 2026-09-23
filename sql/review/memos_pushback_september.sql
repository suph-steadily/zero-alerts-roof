-- RUN 2026-09-23, first SELECT completed, 474 aggregate rows. Other SELECTs NOT RUN unless logged. Metabase db 235.
-- Purpose: September 23 aggregate sensitivity; original auto/hand removals, re-additions, latest state, fixed 45-day clock.
-- Claims: O5 O6 O7 O8 A50
-- Expected if the memo is right: Aug25 original all-age cohort: auto 9/436 and hand 29/2774; all 9 auto latest off; hand stayed-off unknown.
-- September 23 sensitivity, NOT RUN. Endorsement-only removal undercounts other workflows.
-- This is an executable state-history aggregate and exact audit-source discovery, not a completed audit actor join.
-- Original rows can drift; reconciling the original 29 and 9 requires the August snapshot or event history.
-- Tie check required: same (policy,dwelling,issued timestamp,quote) must not contain conflicting coverage.
-- Age here is issue-year minus year built; original memo used 2026-year_built for ranges.
-- The output contains aggregate state-month cells only, with no entity identifiers.
WITH toDateTime('2026-09-24 00:00:00') AS cutoff,
nb_choice AS (
 SELECT policy_id,dwelling_id,
 argMin(tuple(quote_issued_timestamp,prop_cov_roof_surfacing_exclusion,pol_ff_automated_roof_exclusion,pol_prop_steadily_roof_condition_score_decision,pol_prop_year_built,pol_prop_state,pol_created_timestamp,pol_prop_steadily_roof_condition_score_condition_score),
 tuple(quote_issued_timestamp,quote_id)) AS row
 FROM dbt.ipod_standard_mga_raw_policy_info
 WHERE quote_type='NewBusiness' AND quote_status='Issued'
 AND pol_created_timestamp>=toDateTime('2026-04-01 00:00:00')
 AND quote_issued_timestamp IS NOT NULL AND quote_issued_timestamp<cutoff
 GROUP BY policy_id,dwelling_id
), nb AS (
 SELECT policy_id,dwelling_id,row.1 AS bind_ts,
 if(row.3='yes' AND row.4='exclude','auto','hand') AS lane,
 if(toYear(row.1)-row.5>=101,'101+','under101_or_unknown') AS age_band,
 row.6 AS state,row.7 AS created,row.8 AS score
 FROM nb_choice WHERE row.2='selected'
), endo AS (
 SELECT policy_id,dwelling_id,quote_issued_timestamp AS ts,prop_cov_roof_surfacing_exclusion AS rse
 FROM dbt.ipod_standard_mga_raw_policy_info
 WHERE quote_type='Endorsement' AND quote_status='Issued'
 AND quote_issued_timestamp>=toDateTime('2026-04-01 00:00:00') AND quote_issued_timestamp<cutoff
), removed AS (
 SELECT n.policy_id AS policy_id,n.dwelling_id AS dwelling_id,n.bind_ts AS bind_ts,n.lane AS lane,n.age_band AS age_band,n.state AS state,n.created AS created,n.score AS score,
 minIf(e.ts,e.ts>n.bind_ts AND e.rse!='selected') AS removed_ts,
 countIf(e.ts>n.bind_ts AND e.rse!='selected')>0 AS ever_removed
 FROM nb n LEFT JOIN endo e ON n.policy_id=e.policy_id AND n.dwelling_id=e.dwelling_id
 GROUP BY n.policy_id,n.dwelling_id,n.bind_ts,n.lane,n.age_band,n.state,n.created,n.score
), final AS (
 SELECT r.policy_id AS policy_id,r.dwelling_id AS dwelling_id,r.bind_ts AS bind_ts,r.lane AS lane,r.age_band AS age_band,r.state AS state,r.created AS created,r.score AS score,r.removed_ts AS removed_ts,r.ever_removed AS ever_removed,
 countIf(e.ts>r.removed_ts AND e.rse='selected' AND r.ever_removed)>0 AS readded_after_removal,
 argMaxIf(e.rse,e.ts,e.ts>r.bind_ts) AS latest_endo_rse
 FROM removed r LEFT JOIN endo e ON r.policy_id=e.policy_id AND r.dwelling_id=e.dwelling_id
 GROUP BY r.policy_id,r.dwelling_id,r.bind_ts,r.lane,r.age_band,r.state,r.created,r.score,r.removed_ts,r.ever_removed
)
SELECT lane,age_band,state,toStartOfMonth(created) AS creation_month,
 count() AS excluded_dwellings,
 countIf(bind_ts<toDateTime('2026-08-26 00:00:00')) AS original_period_dwellings,
 countIf(bind_ts<toDateTime('2026-08-26 00:00:00') AND ever_removed AND removed_ts<toDateTime('2026-08-26 00:00:00')) AS original_period_removed,
 countIf(bind_ts<toDateTime('2026-08-26 00:00:00') AND ever_removed AND removed_ts<toDateTime('2026-08-26 00:00:00') AND NOT readded_after_removal) AS original_removed_never_readded,
 countIf(bind_ts<toDateTime('2026-08-26 00:00:00') AND ever_removed AND removed_ts<toDateTime('2026-08-26 00:00:00') AND latest_endo_rse!='selected') AS original_removed_latest_off,
 countIf(ever_removed) AS ever_removed_dwellings,
 countIf(ever_removed AND NOT readded_after_removal) AS never_readded_dwellings,
 countIf(bind_ts<=cutoff-INTERVAL 45 DAY) AS full_45d_dwellings,
 countIf(bind_ts<=cutoff-INTERVAL 45 DAY AND ever_removed AND removed_ts<=bind_ts+INTERVAL 45 DAY) AS removed_within45d,
 quantileExactIf(0.5)(dateDiff('day',bind_ts,removed_ts),ever_removed) AS median_removal_days
FROM final GROUP BY lane,age_band,state,creation_month ORDER BY lane,age_band,state,creation_month
SETTINGS join_use_nulls=1;
