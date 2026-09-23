-- RUN 2026-09-23. 1224 aggregate rows. See review/threshold_empirical_runs.json.
-- Purpose: every integer bar with home label counts and home/quote capacity, preserving existing auto exclusions.
-- Claims: user follow-up on choosing the bar; A1 A16 A33 A39 A40 A51.
-- Expected: historical v1.2.0 issued bar 85 -> bar 83 adds 38 hand signatures and 56 previously unexcluded homes.
-- SELECT only; aggregate output only. Run threshold_empirical_audit.sql first and require unique quote-home rows.
-- Score/model/coverage are current-row proxies, not the score or coverage at referral or issue.
-- Eligibility excludes CO/RI/WV only in primary/monthly cohorts; form availability is unresolved.
-- Historical cohort uses original all-state May 1-August 15 dates with explicit Chicago and a new fixed issue cutoff.
-- Month cohorts use complete calendar months May-August, which are not equal to the historical partial August.
-- Current-auto signature = selected + flag yes + decision exclude; inferred hand = selected but not current auto.
-- Selector is current_auto OR score>=bar. Bar 101 retains current auto and adds no scored homes if the audit passes.
WITH base AS (
 SELECT policy_id,quote_id,dwelling_id,
   pol_created_timestamp AS created_at,
   quote_status='Issued' AND quote_issued_timestamp<toDateTime('2026-09-23','America/Chicago') AS bound,
   pol_prop_state AS state,
   pol_prop_steadily_roof_condition_score_condition_score AS score,
   multiIf(prop_cov_roof_surfacing_exclusion='selected'
     AND pol_ff_automated_roof_exclusion='yes'
     AND pol_prop_steadily_roof_condition_score_decision='exclude','auto',
     prop_cov_roof_surfacing_exclusion='selected','hand','none') AS lane
 FROM dbt.ipod_standard_mga_raw_policy_info
 WHERE quote_type='NewBusiness'
   AND pol_created_timestamp>=toDateTime('2026-05-01','America/Chicago')
   AND pol_created_timestamp<toDateTime('2026-09-01','America/Chicago')
   AND pol_prop_year_built>1700
   AND toYear(toTimeZone(pol_created_timestamp,'America/Chicago'))-pol_prop_year_built>=101
   AND pol_prop_steadily_roof_condition_score_model_version='v1.2.0'
), expanded AS (
 SELECT *,arrayJoin([
   if(created_at<toDateTime('2026-08-16','America/Chicago'),'historical_May01_Aug15',''),
   if(created_at>=toDateTime('2026-07-30','America/Chicago') AND state NOT IN ('CO','RI','WV'),'primary_Jul30_Aug31',''),
   if(state NOT IN ('CO','RI','WV'),concat('month_',formatDateTime(toTimeZone(created_at,'America/Chicago'),'%Y-%m')),'')
 ]) AS cohort,
 arrayJoin(['all_current_quotes','issued_by_Sep22']) AS population,
 arrayJoin(range(102)) AS bar
 FROM base
 WHERE cohort!='' AND (population='all_current_quotes' OR bound)
), q AS (
 SELECT cohort,population,bar,quote_id,any(policy_id) AS policy_id,
   count() AS homes,countIf(score IS NULL) AS unscored_homes,
   countIf(lane='auto') AS auto_homes,countIf(lane='hand') AS hand_homes,countIf(lane='none') AS none_homes,
   countIf(lane='auto' AND score IS NULL) AS auto_unscored,
   countIf(lane='hand' AND score IS NULL) AS hand_unscored,
   countIf(lane='none' AND score IS NULL) AS none_unscored,
   countIf(lane='hand' AND score>=bar) AS caught_hand_homes,
   countIf(lane='none' AND score>=bar) AS added_none_homes,
   countIf(score>=bar) AS score_selected_homes,
   countIf(lane='auto' OR score>=bar) AS selected_homes
 FROM expanded GROUP BY cohort,population,bar,quote_id
)
SELECT cohort,population,bar,count() AS quotes,uniqExact(policy_id) AS policy_clusters,
 sum(q.homes) AS homes,sum(q.unscored_homes) AS unscored_homes,
 sum(q.auto_homes) AS auto_homes,sum(q.hand_homes) AS hand_homes,sum(q.none_homes) AS none_homes,
 sum(q.auto_unscored) AS auto_unscored,sum(q.hand_unscored) AS hand_unscored,sum(q.none_unscored) AS none_unscored,
 sum(q.caught_hand_homes) AS caught_hand_homes,sum(q.added_none_homes) AS added_none_homes,
 sum(q.score_selected_homes) AS score_selected_homes,sum(q.selected_homes) AS selected_homes,
 countIf(q.auto_homes>0) AS current_auto_quotes,
 countIf(q.score_selected_homes>0) AS score_selected_quotes,
 countIf(q.selected_homes>0) AS selected_quotes,
 countIf(q.auto_homes=0 AND q.selected_homes>0) AS added_selected_quotes,
 countIf(q.hand_homes>0) AS any_hand_quotes,
 countIf(q.caught_hand_homes>0) AS any_caught_hand_quotes,
 countIf(q.auto_homes=0 AND q.hand_homes=0) AS previously_no_exclusion_quotes,
 countIf(q.auto_homes=0 AND q.hand_homes=0 AND q.selected_homes>0) AS added_previously_no_exclusion_quotes,
 countIf(q.auto_homes=0 AND q.hand_homes>0 AND q.selected_homes>0) AS added_quotes_with_some_hand_exclusion,
 countIf(q.unscored_homes=q.homes) AS entirely_unscored_quotes,
 100.0*selected_homes/nullIf(homes,0) AS selected_home_pct,
 100.0*selected_quotes/nullIf(quotes,0) AS selected_quote_pct,
 100.0*caught_hand_homes/nullIf(hand_homes,0) AS hand_capture_pct,
 100.0*added_none_homes/nullIf(none_homes,0) AS previously_unexcluded_selection_pct
FROM q GROUP BY cohort,population,bar ORDER BY cohort,population,bar;
-- Quote capacity is any selected eligible v1.2.0 home. Other homes on a quote are outside this home cohort.
-- any_caught_hand_quotes and added_previously_no_exclusion_quotes do not partition all selected quotes:
-- a quote can contain both hand and none homes. Home-level H and N are the additive utility inputs.
-- Issued is an observed status by a common cutoff, not equal follow-up or a randomized binding effect.
