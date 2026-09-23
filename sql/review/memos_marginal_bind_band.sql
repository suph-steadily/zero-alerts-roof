-- RUN 2026-09-23, first SELECT completed, 297 aggregate rows. Other SELECTs NOT RUN unless logged. Metabase db 235.
-- Purpose: Count the marginal 85-89 band separately at 101+, alongside all-age Q10.
-- Claims: O4 A4 A32
-- Expected if the memo is right: Original all-age Apr15-Jul31 flag-on rates: 10.59% vs 13.35%; missing 101+ counts unknown.
-- Faithful Q10 diagnostic, not score matching: maximum score and exclude decision may be on different dwellings.
-- It reports versions separately, including v1.2.0; definitive analysis must use same dwelling at decision time.
-- Quotes qualify as 101+ if any valid dwelling is 101+, as in bind memo; a strict same-home cut is also required.
-- No statistical or causal worst-case bound follows from this selected comparison.
WITH q AS (
 SELECT quote_id,max(quote_status='Issued') AS issued,
 max(pol_ff_automated_roof_exclusion='yes') AS flag_on,max(pol_prop_steadily_roof_condition_score_condition_score) AS score,
 max(pol_prop_steadily_roof_condition_score_decision='exclude') AS exclude_decision,
 max(prop_cov_roof_surfacing_exclusion='selected') AS selected,
 max(pol_prop_year_built>1700 AND 2026-pol_prop_year_built>=101) AS any101,
 groupUniqArray(pol_prop_steadily_roof_condition_score_model_version) AS versions,groupUniqArray(pol_prop_state) AS states
 FROM dbt.ipod_standard_mga_raw_policy_info WHERE quote_type='NewBusiness'
 AND pol_created_timestamp>=toDateTime('2026-04-15 00:00:00')
 AND pol_created_timestamp<toDateTime('2026-08-01 00:00:00')
 AND toDate(pol_created_timestamp) NOT IN (toDate('2026-04-27'),toDate('2026-04-28'),toDate('2026-05-29'))
 GROUP BY quote_id
), p AS (
 SELECT *,arrayJoin(if(any101,['all_ages','101+'],['all_ages'])) AS population
 FROM q
)
SELECT population,versions[1] AS model_version,states[1] AS state,
 multiIf(score>=95,'95+',score>=90,'90-94','85-89') AS score_band,
 exclude_decision,count() AS quotes,sum(issued) AS issued_quotes,
 countIf(selected) AS quotes_with_selected_coverage,100.0*issued_quotes/quotes AS bind_pct
FROM p WHERE flag_on AND score>=85 AND length(versions)=1 AND length(states)=1
AND states[1] NOT IN ('CO','RI','WV')
GROUP BY population,model_version,state,score_band,exclude_decision
ORDER BY population,model_version,state,score_band,exclude_decision;
