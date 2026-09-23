-- RUN 2026-09-23, first SELECT completed, 789 aggregate rows. Other SELECTs NOT RUN unless logged. Metabase db 235.
-- Purpose: September 23 sensitivity: full 60-day issue clock for auto and comparator, all three age bands.
-- Claims: N11 A50
-- Expected if the memo is right: At Aug20, creation-clock E3 subset had 0/186 auto; September issue-clock count is not known.
-- September 23 current-day cutoff; aggregate sensitivity.
-- Outcome is first Inspection cancellation transaction within 60 days, not NOC letters or sustained cancellation.
-- Compute expected auto events by age/state/issue-month none rates; retain unmatched-cell counts.
-- All ages are output separately; 91-100 auto is retained even when its count is zero.
-- First issued NB selection is deterministic; historical model/coverage revisions still need event data.
WITH toDate('2026-09-23') AS as_of,
first_nb AS (
 SELECT policy_id,argMin(quote_id,tuple(quote_issued_timestamp,quote_id)) AS issued_quote
 FROM dbt.ipod_standard_mga_raw_policy_info WHERE quote_type='NewBusiness' AND quote_status='Issued'
 AND quote_issued_timestamp IS NOT NULL GROUP BY policy_id
), coh AS (
 SELECT p.policy_id,min(toDate(p.quote_issued_timestamp)) AS issued,
 max(toYear(p.quote_issued_timestamp)-p.pol_prop_year_built) AS age,
 max(p.prop_cov_roof_surfacing_exclusion='selected') AS rse,
 max(p.prop_cov_roof_surfacing_exclusion='selected' AND p.pol_ff_automated_roof_exclusion='yes' AND p.pol_prop_steadily_roof_condition_score_decision='exclude') AS auto,
 groupUniqArray(p.pol_prop_state) AS states
 FROM dbt.ipod_standard_mga_raw_policy_info p INNER JOIN first_nb n ON p.policy_id=n.policy_id AND p.quote_id=n.issued_quote
 WHERE p.quote_type='NewBusiness' AND p.quote_status='Issued'
 AND p.pol_created_timestamp>=toDateTime('2026-04-21 00:00:00')
 AND p.pol_created_timestamp<toDateTime('2026-08-03 00:00:00') AND p.pol_prop_year_built>1700
 GROUP BY p.policy_id
), fc AS (
 SELECT policy_id,min(toDate(quote_issued_timestamp)) AS cancelled,
 argMin(cancellation_reason,tuple(quote_issued_timestamp,quote_id)) AS reason
 FROM dbt.ipod_standard_mga_raw_policy_info WHERE quote_type='Cancellation' AND quote_status='Issued'
 AND toDate(quote_issued_timestamp)<=as_of GROUP BY policy_id
), j AS (
 SELECT c.policy_id AS policy_id,c.issued AS issued,
 multiIf(c.age>=101,'101+',c.age>=91,'91-100','90_under') AS age_band,
 multiIf(c.auto,'auto',c.rse,'hand','none') AS lane,
 if(length(c.states)=1,c.states[1],'MULTI_STATE') AS state,
 f.reason='Inspection' AND f.cancelled>=c.issued AND f.cancelled<=c.issued+INTERVAL 60 DAY AS inspection_cancel60,
 f.reason='NonCompliance' AND f.cancelled>=c.issued AND f.cancelled<=c.issued+INTERVAL 60 DAY AS noncompliance_cancel60
 FROM coh c LEFT JOIN fc f ON c.policy_id=f.policy_id
 WHERE c.issued<=as_of-INTERVAL 60 DAY
)
SELECT age_band,state,toStartOfMonth(issued) AS issue_month,lane,count() AS full_clock_policies,
 coalesce(sum(inspection_cancel60),0) AS inspection_cancels_60d,
 coalesce(sum(noncompliance_cancel60),0) AS noncompliance_cancels_60d,
 100.0*inspection_cancels_60d/full_clock_policies AS inspection_cancel_pct_60d
FROM j GROUP BY age_band,state,issue_month,lane ORDER BY age_band,state,issue_month,lane
SETTINGS join_use_nulls=1;

