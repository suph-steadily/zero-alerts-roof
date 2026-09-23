-- RUN 2026-09-23, completed, 2 aggregate rows. Metabase db 235, SELECT only.
-- Purpose: full365-day issue-clock comparison within the original Jan2024-Jun2026 creation cohort.
-- Claims: N9 N10 A27. Expected: original creation-clock101+E1 was50/487 versus774/9059; corrected issue-clock unknown.
-- Oldest dwelling age at issue101+; issue on/beforeAug20 2025; outcome cutoffAug20 2026 inclusive.
-- Calendar dates and cohort boundaries explicitly America/Chicago. All policies have a full365-day clock.
-- First Inspection cancellation transaction, not NOC letters; NonCompliance separately counted.
-- Any coverage sets policy lane; excludes only on younger siblings are retained, as in the original policy-grain design.
-- Current canonical issued NB quote and inferred actor signature; later reinstatements are not removed.
WITH first_nb AS (
 SELECT policy_id,argMin(quote_id,tuple(quote_issued_timestamp,quote_id)) AS issued_quote
 FROM dbt.ipod_standard_mga_raw_policy_info
 WHERE quote_type='NewBusiness' AND quote_status='Issued' AND quote_issued_timestamp IS NOT NULL
 GROUP BY policy_id
), coh AS (
 SELECT p.policy_id,min(toDate(toTimeZone(p.pol_created_timestamp,'America/Chicago'))) AS created,
 min(toDate(toTimeZone(p.quote_issued_timestamp,'America/Chicago'))) AS issued,
 max(toYear(toTimeZone(p.quote_issued_timestamp,'America/Chicago'))-p.pol_prop_year_built) AS issue_age,
 max(toYear(toTimeZone(p.pol_created_timestamp,'America/Chicago'))-p.pol_prop_year_built) AS creation_age,
 max(p.prop_cov_roof_surfacing_exclusion='selected') AS rse,
 max(p.prop_cov_roof_surfacing_exclusion='selected' AND p.pol_ff_automated_roof_exclusion='yes' AND p.pol_prop_steadily_roof_condition_score_decision='exclude') AS auto,
 groupUniqArray(p.pol_prop_state) AS states
 FROM dbt.ipod_standard_mga_raw_policy_info AS p INNER JOIN first_nb AS n ON p.policy_id=n.policy_id AND p.quote_id=n.issued_quote
 WHERE p.quote_type='NewBusiness' AND p.quote_status='Issued'
 AND p.pol_created_timestamp>=toDateTime('2024-01-01 00:00:00','America/Chicago')
 AND p.pol_created_timestamp<toDateTime('2026-07-01 00:00:00','America/Chicago') AND p.pol_prop_year_built>1700
 GROUP BY p.policy_id
), first_cancel AS (
 SELECT policy_id,min(toDate(toTimeZone(quote_issued_timestamp,'America/Chicago'))) AS cancelled,
 argMin(cancellation_reason,tuple(quote_issued_timestamp,quote_id)) AS reason
 FROM dbt.ipod_standard_mga_raw_policy_info
 WHERE quote_type='Cancellation' AND quote_status='Issued'
 AND quote_issued_timestamp<toDateTime('2026-08-21 00:00:00','America/Chicago') GROUP BY policy_id
)
SELECT multiIf(c.auto,'auto',c.rse,'hand','none') AS lane,
 count() AS full_365d_policies,
 countIf(f.reason='Inspection' AND f.cancelled>=c.issued AND f.cancelled<=c.issued+INTERVAL 365 DAY) AS inspection_cancels_365d,
 countIf(f.reason='NonCompliance' AND f.cancelled>=c.issued AND f.cancelled<=c.issued+INTERVAL 365 DAY) AS noncompliance_cancels_365d,
 100.0*inspection_cancels_365d/full_365d_policies AS inspection_cancel_pct_365d,
 min(c.issued) AS first_issue_date,max(c.issued) AS last_issue_date
FROM coh c LEFT JOIN first_cancel f ON c.policy_id=f.policy_id
WHERE c.issue_age>=101 AND c.issued<=toDate('2025-08-20')
GROUP BY lane ORDER BY lane
SETTINGS join_use_nulls=1;
