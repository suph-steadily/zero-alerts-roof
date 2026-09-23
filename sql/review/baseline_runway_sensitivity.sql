-- RUN 2026-09-23. Completed SELECTs; returned rows per statement: 4.
-- Purpose: expose dependence of claimed30% censoring on an unverified observation cutoff.
-- Claim IDs: S23 RS19 A24 A26.
-- Expected if the first read is right: approximately30% of April+ snapshot policies
-- lack90 days at the actual documented cutoff. Listed cutoffs below are sensitivities,
-- NOT assertions about the snapshot. Only aggregate outputs.
WITH coh AS (
 SELECT o_policy_id,min(o_bind_ts) AS bind_ts
 FROM dbt_dev.damr_uarnoe_cohort_20260816 GROUP BY o_policy_id
), expanded AS (
 SELECT *,arrayJoin([toDate('2026-08-14'),toDate('2026-08-15'),toDate('2026-08-16'),toDate('2026-08-20')]) AS assumed_cutoff
 FROM coh WHERE toDate(bind_ts)>=toDate('2026-04-01')
)
SELECT assumed_cutoff,assumed_cutoff-90 AS last_full_90day_bind,
       count() AS april_plus_snapshot_policies,
       countIf(dateDiff('day',toDate(bind_ts),assumed_cutoff)<90) AS policies_without90days,
       100.0*policies_without90days/nullIf(april_plus_snapshot_policies,0) AS pct_without90days,
       countIf(dateDiff('day',toDate(bind_ts),assumed_cutoff)>=60) AS policies_with60days
FROM expanded GROUP BY assumed_cutoff;
-- Retrieve the snapshot build manifest before choosing a cutoff. A maximum event date
-- cannot establish that event-free policies were observed through the same date.
