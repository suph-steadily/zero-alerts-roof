-- Purpose: size current and maximum pass-through routing on the same quote/home cohort.
-- Claims: P15, O10, RS35, A41, A45. Expected: current 65-70/month is ALL AGES;
-- the printed 101+ bound-home incremental proxy is (557+528)/3.5=310/month at83,
-- (618+682)/3.5=371.43/month at80, excluding existing auto rows. No exact traffic forecast exists.
-- RUN 2026-09-23, 6 aggregate rows in review/root_runs.json. Current-row proxy only.
-- Decision-time and eligible-form mappings remain unresolved.
-- Pass-through is an upper bound assuming no other alert sends the quote to UW and no
-- attestation removes coverage. It is not the expected launched volume.
-- Grain: unique quote-home, then quotes; age = creation year - per-home year_built.
-- Window: explicit America/Chicago, NB creations Jul30-Aug31 2026; fixed bind outcome through Sep22 2026.
WITH homes AS (
 SELECT quote_id, dwelling_id, min(pol_created_timestamp) AS created_at,
   max(quote_status='Issued' AND quote_issued_timestamp < toDateTime('2026-09-23','America/Chicago')) AS bound,
   max(pol_prop_steadily_roof_condition_score_condition_score) AS score,
   max(prop_cov_roof_surfacing_exclusion='selected'
     AND pol_ff_automated_roof_exclusion='yes'
     AND pol_prop_steadily_roof_condition_score_decision='exclude') AS current_auto
 FROM dbt.ipod_standard_mga_raw_policy_info
 WHERE quote_type='NewBusiness'
   AND pol_created_timestamp >= toDateTime('2026-07-30','America/Chicago')
   AND pol_created_timestamp < toDateTime('2026-09-01','America/Chicago')
   AND pol_prop_year_built >1700
   AND toYear(toTimeZone(pol_created_timestamp,'America/Chicago'))-pol_prop_year_built >=101
   AND pol_prop_state NOT IN ('CO','RI','WV')
   AND pol_prop_steadily_roof_condition_score_model_version='v1.2.0'
 GROUP BY quote_id,dwelling_id
), gates AS (
 SELECT quote_id,max(toUInt8(requires_uw_review)) AS gate
 FROM dbt_upc.uw_alerts_per_quote
 WHERE alert_category NOT IN ('DATA_SAFEGUARD','VALIDATION','SHOWSTOPPER','SYSTEM_ERROR')
 GROUP BY quote_id
), refs AS (
 SELECT DISTINCT JSONExtractString(data,'quote_id') AS quote_id
 FROM raw_pg_eventstore.eventstore_good_events
 WHERE name='underwriting_review_note'
   AND created_at >= toDateTime('2026-03-15','America/Chicago')
   AND created_at < toDateTime('2026-09-23','America/Chicago')
), q AS (
 SELECT h.quote_id,bar,toStartOfMonth(toTimeZone(min(h.created_at),'America/Chicago')) AS created_month,
  max(h.bound) AS bound,count() AS eligible_homes,
  countIf(h.current_auto OR h.score>=bar) AS selected_homes,
  max(h.current_auto OR h.score>=bar) AS selected_quote,
  max(coalesce(g.gate,0)) AS any_gate,
  max(h.quote_id IN (SELECT quote_id FROM refs)) AS any_referral_note
 FROM homes h CROSS JOIN (SELECT arrayJoin([80,83,85]) AS bar) AS bars
 LEFT JOIN gates g ON g.quote_id=h.quote_id
 GROUP BY h.quote_id,bar
)
SELECT created_month,bar,count() AS quotes,sum(eligible_homes) AS homes,
 sum(selected_quote) AS pass_through_upper_quote_count,
 sum(selected_homes) AS pass_through_upper_home_count,
 countIf(selected_quote AND any_gate=0 AND any_referral_note=0) AS current_routing_no_review_proxy_quotes,
 sumIf(selected_homes,any_gate=0 AND any_referral_note=0) AS current_routing_no_review_proxy_homes,
 countIf(selected_quote AND bound) AS observed_bound_pass_through_upper_quotes,
 sumIf(selected_homes,bound) AS observed_bound_pass_through_upper_homes
FROM q GROUP BY created_month,bar ORDER BY created_month,bar;
