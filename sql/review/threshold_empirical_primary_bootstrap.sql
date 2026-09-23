-- RUN 2026-09-23. 2000 policy-clustered draws over every integer 0-101; 102 aggregate rows; 1427 policies.
-- Final log: review/threshold_empirical_primary_full_bootstrap_runs.json; preliminary 27-bar log retained separately.
-- Purpose: uncertainty around each integer threshold 0-101 and conservative utility winner frequencies.
-- Claims: user follow-up on choosing the bar; A33 A51.
-- Expected: no prescribed winning bar. This samples historical current-row signatures, not future sales or losses.
-- SELECT only; aggregate output only. 2000 deterministic policy-clustered Efron draws; seed 20260923.
-- Primary population: v1.2.0 issued NB homes by September 22, creation July 30-August 31 Chicago, year built >1700, age>=101, CO/RI/WV excluded.
-- Existing auto signatures contribute zero H/N increments and stay selected; bar 101 is their baseline.
-- Candidate grid is every integer 0-101. Win frequencies compare the full score grid, not an identified economic optimum.
-- R means net value per matched hand coverage decision / net cost per newly excluded none home.
-- It is not a count of underwriting touches saved. Shared age-alert removal savings cancel between bars.
-- Equal-utility ties choose the higher bar. Zero-delta and infeasible-window handling are explicit below.
WITH
 arrayReverse(range(toUInt64(102))) AS bars,
 2000 AS replicates,
 per_policy AS (
  SELECT policy_id,
    countIf(prop_cov_roof_surfacing_exclusion='selected'
      AND NOT(pol_ff_automated_roof_exclusion='yes' AND pol_prop_steadily_roof_condition_score_decision='exclude')) AS hand_n,
    groupArray(tuple(pol_prop_steadily_roof_condition_score_condition_score,
      multiIf(prop_cov_roof_surfacing_exclusion='selected' AND pol_ff_automated_roof_exclusion='yes'
              AND pol_prop_steadily_roof_condition_score_decision='exclude','auto',
              prop_cov_roof_surfacing_exclusion='selected','hand','none'))) AS homes
  FROM dbt.ipod_standard_mga_raw_policy_info
  WHERE quote_type='NewBusiness' AND quote_status='Issued'
    AND quote_issued_timestamp<toDateTime('2026-09-23','America/Chicago')
    AND pol_created_timestamp>=toDateTime('2026-07-30','America/Chicago')
    AND pol_created_timestamp<toDateTime('2026-09-01','America/Chicago')
    AND pol_prop_year_built>1700 AND toYear(toTimeZone(pol_created_timestamp,'America/Chicago'))-pol_prop_year_built>=101
    AND pol_prop_state NOT IN ('CO','RI','WV')
    AND pol_prop_steadily_roof_condition_score_model_version='v1.2.0'
  GROUP BY policy_id
 ), clusters AS (
  SELECT row_number() OVER(ORDER BY policy_id) AS cluster_index,hand_n,
    arrayMap(b->arrayCount(h->tupleElement(h,2)='hand' AND tupleElement(h,1)>=b,homes),bars) AS catches,
    arrayMap(b->arrayCount(h->tupleElement(h,2)='none' AND tupleElement(h,1)>=b,homes),bars) AS overs
  FROM per_policy
 ), (SELECT count() FROM clusters) AS n_clusters,
 sampled AS (
  SELECT d.number AS draw,
    1+modulo(cityHash64(d.number,slot.cluster_index,toUInt64(20260923)),n_clusters) AS cluster_index
  FROM numbers(2000) d CROSS JOIN clusters slot
 ), draw_totals AS (
  SELECT s.draw,sum(c.hand_n) AS hand_n,
    sumForEach(c.catches) AS catches,sumForEach(c.overs) AS overs
  FROM sampled s INNER JOIN clusters c ON c.cluster_index=s.cluster_index GROUP BY s.draw
 ), points AS (
  SELECT draw,hand_n,catches,overs,
    arrayJoin(arrayEnumerate(bars)) AS i,bars[i] AS bar,
    catches[i] AS catch_n,overs[i] AS over_n,
    if(i=1,0,toInt64(catches[i])-toInt64(catches[i-1])) AS delta_catch,
    if(i=1,0,toInt64(overs[i])-toInt64(overs[i-1])) AS delta_over,
    greatest(0.,arrayMax(arrayMap(k->if(catches[i]>catches[k],
      (toFloat64(overs[i])-toFloat64(overs[k]))/nullIf(toFloat64(catches[i])-toFloat64(catches[k]),0.),0.),arrayEnumerate(bars)))) AS r_lower,
    arrayMin(arrayMap(k->if(catches[i]<catches[k],
      (toFloat64(overs[k])-toFloat64(overs[i]))/nullIf(toFloat64(catches[k])-toFloat64(catches[i]),0.),1e100),arrayEnumerate(bars))) AS r_upper,
    arrayExists(k->catches[k]=catches[i] AND overs[k]<overs[i],arrayEnumerate(bars)) AS same_catch_dominated
  FROM draw_totals
 )
SELECT bar,replicates AS draws,n_clusters AS policy_clusters,
  quantilesExact(0.025,0.5,0.975)(catch_n) AS catches_ci,
  quantilesExact(0.025,0.5,0.975)(over_n) AS over_applies_ci,
  quantilesExact(0.025,0.5,0.975)(100.*catch_n/nullIf(hand_n,0)) AS capture_pct_ci,
  countIf(i>1 AND delta_catch>0) AS finite_step_draws,
  quantilesExactIf(0.025,0.5,0.975)(1.*delta_over/nullIf(delta_catch,0),i>1 AND delta_catch>0) AS finite_step_cost_ci,
  countIf(i>1 AND delta_catch=0 AND delta_over>0) AS infinite_step_draws,
  countIf(i>1 AND delta_catch=0 AND delta_over=0) AS no_change_draws,
  countIf(i=1) AS status_quo_no_step_draws,
  countIf(NOT same_catch_dominated AND r_lower<=r_upper) AS nonempty_global_R_window_draws,
  quantilesExactIf(0.025,0.5,0.975)(r_lower,NOT same_catch_dominated AND r_lower<=r_upper) AS feasible_R_lower_ci,
  countIf(NOT same_catch_dominated AND r_lower<=r_upper AND r_upper<1e99) AS finite_R_upper_draws,
  quantilesExactIf(0.025,0.5,0.975)(r_upper,NOT same_catch_dominated AND r_lower<=r_upper AND r_upper<1e99) AS finite_feasible_R_upper_ci,
  countIf(i=indexOf(arrayMap((h,n)->1.0*h-n,catches,overs),arrayMax(arrayMap((h,n)->1.0*h-n,catches,overs)))) AS optimal_at_R1_draws,
  countIf(i=indexOf(arrayMap((h,n)->1.5*h-n,catches,overs),arrayMax(arrayMap((h,n)->1.5*h-n,catches,overs)))) AS optimal_at_R1_5_draws,
  countIf(i=indexOf(arrayMap((h,n)->2.0*h-n,catches,overs),arrayMax(arrayMap((h,n)->2.0*h-n,catches,overs)))) AS optimal_at_R2_draws,
  countIf(i=indexOf(arrayMap((h,n)->3.0*h-n,catches,overs),arrayMax(arrayMap((h,n)->3.0*h-n,catches,overs)))) AS optimal_at_R3_draws,
  countIf(i=indexOf(arrayMap((h,n)->2.7*h-n,catches,overs),arrayMax(arrayMap((h,n)->2.7*h-n,catches,overs)))) AS optimal_at_R2_7_draws
FROM points GROUP BY bar ORDER BY bar DESC;
-- R interval quantiles are conditional on that candidate having a nonempty global window.
-- Report the nonempty fraction beside them; a zero eligible-draw count means its quantile array is a default, NOT an estimate.
-- Upper bound1e100 is an infinity sentinel and is excluded from finite upper quantiles.
-- This samples policy clusters, not independent homes. Intervals quantify this proxy only.
