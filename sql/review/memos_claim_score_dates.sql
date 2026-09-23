-- RUN 2026-09-23, first SELECT completed, 4 aggregate rows. Other SELECTs NOT RUN unless logged. Metabase db 235.
-- Purpose: Independent issue-date versus score-null split for excluded-book roof-peril claims.
-- Claims: O11
-- Expected if the memo is right: Memo: 24 unscored claims totaling40753 dollars; one scored80-89 claim paid399 dollars.
-- Uses creation-clock loss window to diagnose original Q9; report issue-clock sensitivity separately.
-- Do not sum paid_dollars across eligible_matches>1: those claims need validated policy linkage.
-- Parsed claims-file date deduplication is retained. Claim-row tie consistency must be checked before a loss estimate.
-- Aggregate output only; score-null never implies pre-score date.
WITH claims AS (
 SELECT claim_id,dwelling_id,standardized_loss_type AS peril,loss_date,total_paid
 FROM dbt.claims_smga WHERE dwelling_id IS NOT NULL AND dwelling_id!=''
 ORDER BY toDate(concat(splitByChar('-',claims_file)[2],'-',leftPad(splitByChar('-',claims_file)[1],2,'0'),'-01')) DESC
 LIMIT 1 BY claim_id
), nb AS (
 SELECT policy_id,dwelling_id,
 argMin(tuple(toDate(pol_created_timestamp),toDate(quote_issued_timestamp),pol_prop_steadily_roof_condition_score_condition_score,prop_cov_roof_surfacing_exclusion),tuple(quote_issued_timestamp,quote_id)) AS row
 FROM dbt.ipod_standard_mga_raw_policy_info WHERE quote_type='NewBusiness' AND quote_status='Issued'
 AND quote_issued_timestamp IS NOT NULL AND pol_prop_year_built>1700 GROUP BY policy_id,dwelling_id
), matched AS (
 SELECT c.claim_id,n.row.1 AS created,n.row.2 AS issued,n.row.3 AS score,c.total_paid,c.loss_date,
 count() OVER (PARTITION BY c.claim_id) AS eligible_matches
 FROM nb n INNER JOIN claims c ON n.dwelling_id=c.dwelling_id
 WHERE n.row.1>=toDate('2024-01-01') AND n.row.1<toDate('2026-07-01') AND n.row.4='selected'
 AND c.peril IN ('Hail','Wind') AND c.loss_date>=n.row.1
 AND c.loss_date<=least(n.row.1+INTERVAL 365 DAY,toDate('2026-07-31'))
)
SELECT multiIf(issued<toDate('2026-03-16'),'pre_shadow',issued<toDate('2026-04-01'),'March_shadow','April_plus') AS issue_era,
 multiIf(score IS NULL,'unscored',score>=90,'90+',score>=80,'80-89','below80') AS score_band,
 eligible_matches,count() AS claim_matches,uniqExact(claim_id) AS claims,
 sum(total_paid) AS paid_dollars,
 countIf(loss_date<issued) AS losses_before_issue
FROM matched GROUP BY issue_era,score_band,eligible_matches ORDER BY issue_era,score_band,eligible_matches;
