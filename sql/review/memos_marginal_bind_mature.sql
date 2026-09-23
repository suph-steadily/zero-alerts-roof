-- RUN 2026-09-23, completed, 101 aggregate rows. Metabase db 235, SELECT only.
-- Purpose: fixed 14/30-day bind rates in the 101+ quote-level score85-89 band.
-- Claims: O4 A4 A25. Expected: original all-age unclocked band was10.59% versus13.35%; no prior101+ fixed-clock estimate.
-- NB creations Apr15-Jul31 2026; outcomes before Aug26; explicit America/Chicago calendar and boundaries.
-- Age=2026-year_built; quote qualifies if any valid dwelling is101+; score=max across quote dwellings.
-- Current-row signatures and model versions, not historical decision-time records or causal treatment.
-- Exclude holdout states and Apr27/28/May29. Keep only single-state/single-version quotes.
-- A quote enters each horizon only if its entire clock ends before the outcome cutoff.
-- Output every model version separately. Same-dwelling treatment, form eligibility and historical actor remain unresolved.
WITH toDateTime('2026-08-26 00:00:00','America/Chicago') AS outcome_cutoff,
q AS (
 SELECT quote_id,min(pol_created_timestamp) AS created_at,
 countIf(quote_status='Issued' AND quote_issued_timestamp IS NOT NULL)>0 AS has_issue,
 minIf(quote_issued_timestamp,quote_status='Issued' AND quote_issued_timestamp IS NOT NULL) AS issued_at,
 max(pol_ff_automated_roof_exclusion='yes') AS flag_on,
 max(pol_prop_steadily_roof_condition_score_condition_score) AS score,
 max(pol_prop_steadily_roof_condition_score_decision='exclude') AS exclude_decision,
 max(prop_cov_roof_surfacing_exclusion='selected') AS selected,
 max(pol_prop_year_built>1700 AND 2026-pol_prop_year_built>=101) AS any101,
 groupUniqArray(pol_prop_steadily_roof_condition_score_model_version) AS versions,
 groupUniqArray(pol_prop_state) AS states
 FROM dbt.ipod_standard_mga_raw_policy_info
 WHERE quote_type='NewBusiness'
 AND pol_created_timestamp>=toDateTime('2026-04-15 00:00:00','America/Chicago')
 AND pol_created_timestamp<toDateTime('2026-08-01 00:00:00','America/Chicago')
 AND toDate(toTimeZone(pol_created_timestamp,'America/Chicago')) NOT IN
 (toDate('2026-04-27'),toDate('2026-04-28'),toDate('2026-05-29'))
 GROUP BY quote_id
), clocks AS (
 SELECT *,arrayJoin([14,30]) AS horizon_days FROM q
 WHERE any101 AND flag_on AND score>=85 AND score<90
 AND length(versions)=1 AND length(states)=1 AND states[1] NOT IN ('CO','RI','WV')
)
SELECT horizon_days,versions[1] AS model_version,states[1] AS state,
 toStartOfMonth(toTimeZone(created_at,'America/Chicago')) AS creation_month,
 exclude_decision,count() AS full_clock_quotes,
 countIf(has_issue AND issued_at>=created_at AND issued_at<=created_at+toIntervalDay(horizon_days)
 AND issued_at<outcome_cutoff) AS issued_within_clock,
 countIf(has_issue AND issued_at>=created_at AND issued_at<outcome_cutoff) AS issued_by_cutoff,
 countIf(selected) AS quotes_with_selected_coverage,
 100.0*issued_within_clock/full_clock_quotes AS bind_pct_within_clock
FROM clocks WHERE created_at+toIntervalDay(horizon_days)<outcome_cutoff
GROUP BY horizon_days,model_version,state,creation_month,exclude_decision
ORDER BY horizon_days,model_version,state,creation_month,exclude_decision;
