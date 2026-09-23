-- RUN 2026-09-23. 2000 policy-clustered draws completed in8249ms;11 aggregate rows.
-- A20-draw preflight completed first. See review/baseline_bootstrap_runs.json.
-- Purpose: quantify the whole v1.2.0 bound101+ curve, steps and globally feasible R windows.
-- Claim IDs: A33 A34 RS5 RS13 T2 T3. Expected: no preset interval values.
-- Population: current issued NB homes created May1-Aug15 by original timestamp literals;
-- fixed2026-year_built>=101,valid year>1700,v1.2.0; inferred current coverage signatures.
-- All policies in that slice are sampled, including auto-only policies with zero increments.
-- Each draw samples exactly N policies with replacement, carrying every eligible home.
-- Deterministic cityHash64 pseudo-random draws; 2000 replicates, seed20260923.
-- This is not an eligible decision-time curve and does not repair actor/selection errors.
-- R uses value of one operational catch divided by net cost of one new left-alone exclusion.
-- Existing auto exposures are excluded from both increments; bar101 represents status quo.
WITH
 [101,95,90,85,83,80,75,70,65,60,55] AS bars,
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
    AND pol_created_timestamp>=toDateTime('2026-05-01')
    AND pol_created_timestamp<toDateTime('2026-08-16')
    AND pol_prop_year_built>1700 AND 2026-pol_prop_year_built>=101
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
  quantilesExactIf(0.025,0.5,0.975)(r_upper,NOT same_catch_dominated AND r_lower<=r_upper AND r_upper<1e99) AS finite_feasible_R_upper_ci
FROM points GROUP BY bar ORDER BY bar DESC;
-- R interval quantiles are conditional on that candidate having a nonempty global window.
-- Report the nonempty fraction beside them; a zero eligible-draw count means its quantile array is a default, NOT an estimate.
-- Upper bound1e100 is an infinity sentinel and is excluded from finite upper quantiles.
-- This samples policy clusters, not independent homes. Intervals quantify this proxy only.
