-- RUN 2026-09-23, database 235, SELECT only; three statements returned 1, 1 and 33 aggregate rows.
-- Purpose: L7/L9, A28. Verify cumulative snapshot grain, parsed chronology,
-- tie uniqueness, missing dwelling key and book-wide peril totals.
-- Expected at historical 2026-08-21 extraction: 86,317 rows / 7,278 claims;
-- Hail 2,022/$21.9m; Wind 1,355/$15.5m; Water Damage 1,906/$19.3m;
-- Fire 292/$33.3m. Current totals can drift. All ages, all claim file history.
-- Query 1: inventory and parser check, aggregate only.
WITH r AS (
 SELECT *, toDateOrNull(concat(splitByChar('-', claims_file)[2], '-',
        leftPad(splitByChar('-', claims_file)[1], 2, '0'), '-01')) AS fm
 FROM dbt.claims_smga
)
SELECT count() AS snapshot_rows, uniqExact(claim_id) AS distinct_claims,
       countIf(fm IS NULL) AS unparseable_file_rows,
       countIf(dwelling_id IS NULL OR dwelling_id='') AS missing_dwelling_rows,
       min(fm) AS first_file_month, max(fm) AS last_file_month,
       count()/nullIf(uniqExact(claim_id),0) AS row_inflation_factor
FROM r;

-- Query 2: a conflicting latest-month tuple blocks argMax until a tie-breaker is known.
WITH r AS (
 SELECT *, toDateOrNull(concat(splitByChar('-', claims_file)[2], '-',
        leftPad(splitByChar('-', claims_file)[1], 2, '0'), '-01')) AS fm
 FROM dbt.claims_smga
), latest AS (SELECT claim_id,max(fm) AS fm FROM r GROUP BY claim_id),
ties AS (
 SELECT r.claim_id, count() AS rows_at_latest,
        uniqExact(tuple(r.dwelling_id,r.standardized_loss_type,r.loss_date,
                        r.total_paid,r.total_incurred,r.coverage_denied)) AS distinct_tuples
 FROM r INNER JOIN latest l ON r.claim_id=l.claim_id AND r.fm=l.fm GROUP BY r.claim_id
)
SELECT count() AS claims, countIf(rows_at_latest>1) AS duplicate_latest_claims,
       countIf(distinct_tuples>1) AS conflicting_latest_claims FROM ties;

-- Query 3: dedupe first, then classify. Never publish claim descriptions.
WITH r AS (
 SELECT *, toDateOrNull(concat(splitByChar('-', claims_file)[2], '-',
        leftPad(splitByChar('-', claims_file)[1], 2, '0'), '-01')) AS fm
 FROM dbt.claims_smga
), lc AS (
 SELECT claim_id, argMax(tuple(standardized_loss_type,total_paid,total_incurred),fm) AS v
 FROM r WHERE fm IS NOT NULL GROUP BY claim_id
)
SELECT v.1 AS peril, count() AS claims, sum(v.2) AS paid, sum(v.3) AS incurred,
       100.0*count()/sum(count()) OVER () AS claim_share_pct
FROM lc GROUP BY peril ORDER BY claims DESC;
