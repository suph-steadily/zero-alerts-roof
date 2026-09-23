-- Literal counterfactual: remove every selected home with CAPE replacement year 2007-2026;
-- keep unknown, zero, 2006 boundary and older. This is not agent uptake or verified full replacement.
-- Main outputs leave current-auto contribution constant; recent current-auto count supplied separately.
-- RUN 2026-09-23, completed, 204 aggregate rows. Metabase db 235; SELECT only.
-- Test exact policy/quote/dwelling linkage and replacement-year coverage; no row IDs leave the query.
-- Current vendor fields have no verified as-of timestamp or full-replacement semantics.
-- Zero and future years are not valid recent replacements. Duplicate/conflicting source records are exposed.
WITH homes AS (
 SELECT policy_id,quote_id,dwelling_id,
 max(pol_prop_steadily_roof_condition_score_condition_score) AS score,
 max(prop_cov_roof_surfacing_exclusion='selected') AS selected,
 max(prop_cov_roof_surfacing_exclusion='selected' AND pol_ff_automated_roof_exclusion='yes'
 AND pol_prop_steadily_roof_condition_score_decision='exclude') AS auto,
 max(quote_status='Issued' AND quote_issued_timestamp<toDateTime('2026-09-23','America/Chicago')) AS bound
 FROM dbt.ipod_standard_mga_raw_policy_info
 WHERE quote_type='NewBusiness'
 AND pol_created_timestamp>=toDateTime('2026-07-30','America/Chicago')
 AND pol_created_timestamp<toDateTime('2026-09-01','America/Chicago')
 AND pol_prop_year_built>1700
 AND toYear(toTimeZone(pol_created_timestamp,'America/Chicago'))-pol_prop_year_built>=101
 AND pol_prop_state NOT IN ('CO','RI','WV')
 AND pol_prop_steadily_roof_condition_score_model_version='v1.2.0'
 GROUP BY policy_id,quote_id,dwelling_id
), cape AS (
 SELECT policy_id,quote_id,dwelling_id,count() AS source_rows,
 groupUniqArray(roof_replacement_year) AS years,groupUniqArray(roof_age) AS ages
 FROM dbt_upc.ipod_policy_mga_cape GROUP BY policy_id,quote_id,dwelling_id
), j AS (
 SELECT h.*,c.source_rows AS source_rows,c.years AS years,c.ages AS ages,
 multiIf(h.auto,'auto',h.selected,'hand_signature','none') AS lane,
 multiIf(h.score IS NULL,'unscored',h.score>=95,'95+',h.score>=90,'90-94',h.score>=85,'85-89',h.score>=83,'83-84',h.score>=80,'80-82','below80') AS score_band,
 multiIf(coalesce(c.source_rows,0)=0,'unmatched',length(c.years)!=1,'conflicting',c.years[1]=0,'zero',
 c.years[1]>=2007 AND c.years[1]<=2026,'year_2007_2026',c.years[1]=2006,'boundary_2006',
 c.years[1]>=1700 AND c.years[1]<2006,'older',c.years[1]>2026,'future','other') AS year_class
 FROM homes h LEFT JOIN cape c ON h.policy_id=c.policy_id AND h.quote_id=c.quote_id AND h.dwelling_id=c.dwelling_id
)
SELECT arrayJoin(['all_current_quotes','issued_by_Sep22']) AS population,arrayJoin(range(102)) AS bar,
 count() AS homes,countIf(lane='hand_signature') AS all_H,countIf(lane='none') AS all_N,
 countIf(lane='auto') AS all_auto,
 countIf(lane='hand_signature' AND score>=bar) AS selected_H,
 countIf(lane='none' AND score>=bar) AS selected_N,
 countIf(lane='hand_signature' AND score>=bar AND year_class='year_2007_2026') AS removed_H_literal_recent_proxy,
 countIf(lane='none' AND score>=bar AND year_class='year_2007_2026') AS removed_N_literal_recent_proxy,
 countIf(lane='hand_signature' AND score>=bar AND year_class!='year_2007_2026') AS retained_H_literal_recent_proxy,
 countIf(lane='none' AND score>=bar AND year_class!='year_2007_2026') AS retained_N_literal_recent_proxy,
 countIf(lane='hand_signature' AND score>=bar AND year_class IN ('zero','unmatched','boundary_2006')) AS unresolved_H,
 countIf(lane='none' AND score>=bar AND year_class IN ('zero','unmatched','boundary_2006')) AS unresolved_N,
 countIf(lane='auto' AND year_class='year_2007_2026') AS existing_auto_recent_proxy
FROM j
WHERE population='all_current_quotes' OR bound
GROUP BY population,bar ORDER BY population,bar
SETTINGS join_use_nulls=1;
