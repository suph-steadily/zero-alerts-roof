-- RUN 2026-09-23, first SELECT completed, 40 aggregate rows. Other SELECTs NOT RUN unless logged. Metabase db 235.
-- Purpose: Reason-specific cancellation transactions per policy-year, within 101+, and Salesforce coverage.
-- Claims: N1 N6 N7 N8 N18 A27 A42
-- Expected if the memo is right: Creation-basis memo arithmetic: roof 1.19 vs 0.61; ineligible 1.27 vs 1.63 per 100 policy-years.
-- Memo labels its policy-level exposure home-years; this query names it policy-years.
-- NOC letters are not present here. Inspection cancellation transactions include later reinstatements.
-- Creation clock reproduces the memo basis; issue clock is the timing correction.
-- No unverified Salesforce record-order column is assumed: conflicting picklists are counted separately.
-- SF picklists are current, not event-time reasons; exact cancellation-reason histories require discovery.
-- Age is oldest valid dwelling at the selected clock; cross-dwelling exclusion contamination remains visible in the verifier check.
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
), vp AS (
 SELECT splitByChar('/',assumeNotNull(steadily_universal_policy_number__c))[-1] AS pid,
 groupUniqArrayIf(steadily_uw_cancellation_reason__c,coalesce(steadily_uw_cancellation_reason__c,'')!='') AS reasons,
 count() AS records
 FROM tap_veruna.wt_insurance_policy__c FINAL
 WHERE NOT isdeleted AND steadily_universal_policy_number__c IS NOT NULL GROUP BY pid
), clocks AS (
 SELECT *,arrayJoin(['creation','issue']) AS clock,
 if(clock='issue',issued,created) AS start_date,
 if(clock='issue',issue_age,creation_age) AS age,
 multiIf(auto,'auto',rse,'hand','none') AS lane
 FROM coh
), j AS (
 SELECT c.policy_id AS policy_id,c.clock AS clock,c.lane AS lane,c.start_date AS start_date,
 greatest(0,least(dateDiff('day',c.start_date,toDate('2026-08-20')),365,
 if(f.cancelled>=c.start_date,dateDiff('day',c.start_date,f.cancelled),365))) AS exposure_days,
 f.reason='Inspection' AND f.cancelled>=c.start_date
 AND f.cancelled<=least(c.start_date+INTERVAL 365 DAY,toDate('2026-08-20')) AS inspection_cancel,
 coalesce(v.records,0)>0 AS sf_matched,
 multiIf(length(v.reasons)=0,'(unclassified)',length(v.reasons)>1,'(conflicting)',v.reasons[1]) AS sub_reason
 FROM clocks AS c LEFT JOIN first_cancel AS f ON c.policy_id=f.policy_id
 LEFT JOIN vp AS v ON c.policy_id=v.pid WHERE c.age>=101
), exposure AS (
 SELECT clock,lane,count() AS policies,sum(exposure_days)/365.25 AS policy_years,
 countIf(inspection_cancel) AS inspection_cancels,
 countIf(inspection_cancel AND sf_matched) AS sf_matched_cancels,
 countIf(inspection_cancel AND sub_reason='(unclassified)') AS unclassified_cancels,
 countIf(inspection_cancel AND sub_reason='(conflicting)') AS conflicting_cancels
 FROM j GROUP BY clock,lane
), reasons AS (
 SELECT clock,lane,sub_reason,count() AS transactions
 FROM j WHERE inspection_cancel GROUP BY clock,lane,sub_reason
)
SELECT e.clock,e.lane,e.policies,e.policy_years,e.inspection_cancels,
 e.sf_matched_cancels,e.unclassified_cancels,e.conflicting_cancels,
 r.sub_reason,r.transactions,100.0*r.transactions/nullIf(e.policy_years,0) AS per_100_policy_years
FROM exposure AS e LEFT JOIN reasons AS r ON e.clock=r.clock AND e.lane=r.lane
ORDER BY e.clock,e.lane,r.sub_reason
SETTINGS join_use_nulls=1;
