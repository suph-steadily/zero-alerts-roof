-- RUN 2026-09-23, first SELECT completed, 1392 aggregate rows. Other SELECTs NOT RUN unless logged. Metabase db 235.
-- Purpose: Return aggregate decade/state/issue-half-year standardization cells and unmatched exposure.
-- Claims: N3 N4 N5 N14 A30
-- Expected if the memo is right: Original broad 101+ cells reported 203/127.3=1.594; decade and issue-date correction is unknown.
-- Do not drop hand cells without a none comparator silently: report unmatched hand exposure and events.
-- A policy bootstrap must resample both hand and none groups and recompute expected counts per replicate.
-- Aggregate cells alone cannot recover policy exposure variation for that bootstrap.
-- Inspection-order rate must be count(policies with an order before outcome)/all policies by group.
-- The schema query is exact discovery; surveillance adjustment remains blocked until order semantics are validated.
WITH first_nb AS (
 SELECT policy_id,argMin(quote_id,tuple(quote_issued_timestamp,quote_id)) AS issued_quote
 FROM dbt.ipod_standard_mga_raw_policy_info
 WHERE quote_type='NewBusiness' AND quote_status='Issued' AND quote_issued_timestamp IS NOT NULL
 GROUP BY policy_id
), coh AS (
 SELECT p.policy_id,min(toDate(p.pol_created_timestamp)) AS created,
 min(toDate(p.quote_issued_timestamp)) AS issued,
 max(toYear(p.quote_issued_timestamp)-p.pol_prop_year_built) AS issue_age,
 max(toYear(p.pol_created_timestamp)-p.pol_prop_year_built) AS creation_age,
 max(p.prop_cov_roof_surfacing_exclusion='selected') AS rse,
 max(p.prop_cov_roof_surfacing_exclusion='selected' AND p.pol_ff_automated_roof_exclusion='yes' AND p.pol_prop_steadily_roof_condition_score_decision='exclude') AS auto,
 groupUniqArray(p.pol_prop_state) AS states
 FROM dbt.ipod_standard_mga_raw_policy_info AS p INNER JOIN first_nb AS n ON p.policy_id=n.policy_id AND p.quote_id=n.issued_quote
 WHERE p.quote_type='NewBusiness' AND p.quote_status='Issued'
 AND p.pol_created_timestamp>=toDateTime('2024-01-01 00:00:00')
 AND p.pol_created_timestamp<toDateTime('2026-07-01 00:00:00') AND p.pol_prop_year_built>1700
 GROUP BY p.policy_id
), first_cancel AS (
 SELECT policy_id,min(toDate(quote_issued_timestamp)) AS cancelled,
 argMin(cancellation_reason,tuple(quote_issued_timestamp,quote_id)) AS reason
 FROM dbt.ipod_standard_mga_raw_policy_info
 WHERE quote_type='Cancellation' AND quote_status='Issued'
 AND quote_issued_timestamp<toDateTime('2026-08-21 00:00:00') GROUP BY policy_id
), j AS (
 SELECT c.policy_id,if(length(c.states)=1,c.states[1],'MULTI_STATE') AS state,
 concat(toString(toYear(c.issued)),'H',toString(if(toMonth(c.issued)<=6,1,2))) AS issue_half,
 multiIf(c.issue_age>=101,concat(toString(101+10*intDiv(c.issue_age-101,10)),'-',toString(110+10*intDiv(c.issue_age-101,10))),c.issue_age>=91,'91-100','90_under') AS age_band,
 multiIf(c.auto,'auto',c.rse,'hand','none') AS lane,
 greatest(0,least(dateDiff('day',c.issued,toDate('2026-08-20')),365,
 if(f.cancelled>=c.issued,dateDiff('day',c.issued,f.cancelled),365))) AS exposure_days,
 f.reason='Inspection' AND f.cancelled>=c.issued
 AND f.cancelled<=least(c.issued+INTERVAL 365 DAY,toDate('2026-08-20')) AS inspection_cancel
 FROM coh c LEFT JOIN first_cancel f ON c.policy_id=f.policy_id
)
SELECT age_band,state,issue_half,lane,count() AS policies,
 sum(exposure_days)/365.25 AS policy_years,coalesce(sum(inspection_cancel),0) AS inspection_cancels
FROM j WHERE age_band NOT IN ('90_under','91-100') AND lane IN ('hand','none')
GROUP BY age_band,state,issue_half,lane ORDER BY age_band,state,issue_half,lane
SETTINGS join_use_nulls=1;

-- BLOCKED: an inspection-order source and event-time policy link are not established.
SELECT database,table,name,type FROM system.columns
WHERE match(lower(concat(database,'.',table)),'inspect|eventstore')
AND match(lower(name),'order|policy|quote|creat|time|name|data|status')
ORDER BY database,table,name;
