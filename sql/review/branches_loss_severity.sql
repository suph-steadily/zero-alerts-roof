-- RUN 2026-09-23, database 235, SELECT only; 8 aggregate rows; claims_data_through=2026-08-31; explicit America/Chicago.
-- Public output is aggregate only. Never export identifiers from these CTEs.
-- Purpose: L2/L11/L12/L14, A28/A41/A43. Pooled paid/incurred severity,
-- denial rate, and age-specific count, with home/claim denominator explicitly shown.
-- Expected in old ALL-AGE exposure definition: wind/hail excluded n=25, median $477,
-- none n=1,846, median $7,523; below $1,400 = 21/25; denied true = 4/25.
-- New exposure definition can change these counts. Medians here are pooled, not matched.
-- No free-text claim descriptions or individual paid values are returned.
-- Required read-only parameter: claims_data_through, the last covered loss date.
-- RUN parameter on 2026-09-23: claims_data_through=2026-08-31. Metadata identifies
-- claims_file as monthly bordereau; newest file is 8-2026 and max loss date is Aug 31.
-- system.columns comments identify policy_effective_timestamp for exposure, term end
-- as coalesce(policy_effective_end_timestamp,policy_expiration_timestamp), and
-- quote_effective_timestamp for cancellation/reinstatement sequencing. This query
-- uses those effective dates and explicitly measures first spell, not restored exposure.
-- Run branches_loss_cohort.sql and branches_claims_snapshot.sql first. Multiple distinct
-- issued rows per home or conflicting same-file claim tuples require a verified version
-- timestamp and tie-breaker. This query uses one intact issued tuple ordered by issue,
-- quote_version and quote_id, not a claim to decision-time event sourcing. Live census
-- 2026-09-23 found zero duplicate issued (policy,dwelling) keys in this cohort and zero
-- conflicting latest claim files. Effective-date fields are populated on all NB rows.
-- Any ambiguous_claims > 0 blocks quoting until claims have a policy/term join key.
-- This is a corrected estimand, not a promise to reproduce the old flawed exposure totals.
WITH
file_rows AS (
    SELECT *, toDateOrNull(concat(splitByChar('-', claims_file)[2], '-',
           leftPad(splitByChar('-', claims_file)[1], 2, '0'), '-01')) AS file_month
    FROM dbt.claims_smga
),
latest_file AS (SELECT max(file_month) AS file_month FROM file_rows),
claim_tuples AS (
    SELECT claim_id, argMax(tuple(dwelling_id, standardized_loss_type, loss_date,
               total_paid, total_incurred, coverage_denied), file_month) AS r
    FROM file_rows WHERE file_month IS NOT NULL GROUP BY claim_id
),
lc AS (
    SELECT claim_id, r.1 AS dwelling_id, r.2 AS peril, toDate(r.3) AS loss_date,
           r.4 AS paid, r.5 AS incurred, r.6 AS denied
    FROM claim_tuples WHERE r.1 IS NOT NULL AND r.1 != ''
),
issued_tuples AS (
    SELECT policy_id, dwelling_id,
           argMax(tuple(quote_id, toDate(pol_created_timestamp,'America/Chicago'),
                        toDate(quote_issued_timestamp,'America/Chicago'), pol_prop_state,
                        pol_prop_year_built, prop_cov_roof_surfacing_exclusion,
                        pol_ff_automated_roof_exclusion,
                        pol_prop_steadily_roof_condition_score_decision,
                        pol_prop_steadily_roof_condition_score_condition_score,
                        pol_prop_steadily_roof_condition_score_model_version,
                        toDate(policy_effective_timestamp,'America/Chicago'),
                        toDate(coalesce(policy_effective_end_timestamp,policy_expiration_timestamp),'America/Chicago')),
                  tuple(quote_issued_timestamp, quote_version, toString(quote_id))) AS r
    FROM dbt.ipod_standard_mga_raw_policy_info
    WHERE quote_type = 'NewBusiness' AND quote_status = 'Issued'
      AND pol_created_timestamp >= toDateTime('2024-01-01 00:00:00','America/Chicago')
      AND pol_created_timestamp < toDateTime('2026-07-01 00:00:00','America/Chicago')
      AND quote_issued_timestamp IS NOT NULL
    GROUP BY policy_id, dwelling_id
),
bound AS (
    SELECT policy_id, dwelling_id, r.1 AS quote_id, r.2 AS created, r.3 AS issued, r.11 AS bind, r.12 AS term_end,
           r.4 AS st, toYear(r.11) - r.5 AS age,
           concat(toString(toYear(r.11)), 'H', toString(if(toMonth(r.11) <= 6, 1, 2))) AS bh,
           toUInt8(r.6 = 'selected') AS rse,
           multiIf(r.6 != 'selected', 'none', r.7 = 'yes' AND r.8 = 'exclude',
                   'inferred_auto', 'inferred_hand') AS lane,
           r.9 AS score, r.10 AS model_version
    FROM issued_tuples WHERE r.5 > 1700
),
cancel_by_home AS (
    SELECT b.policy_id, b.dwelling_id,
           minOrNullIf(toDate(c.quote_effective_timestamp,'America/Chicago'),
                       c.quote_effective_timestamp IS NOT NULL
                       AND toDate(c.quote_effective_timestamp,'America/Chicago') >= b.bind) AS cancel_date
    FROM bound b
    LEFT JOIN (SELECT policy_id, quote_effective_timestamp
               FROM dbt.ipod_standard_mga_raw_policy_info
               WHERE quote_type = 'Cancellation' AND quote_status = 'Issued') c
           ON c.policy_id = b.policy_id
    GROUP BY b.policy_id, b.dwelling_id
),
coh AS (
    SELECT b.*, least(addDays(b.bind, 365), coalesce(b.term_end,addDays(b.bind,365)),
               addDays({claims_data_through:Date}, 1),
               coalesce(c.cancel_date, addDays(b.bind, 365))) AS end_exclusive,
           greatest(0, dateDiff('day', b.bind, end_exclusive)) AS exp_days
    FROM bound b LEFT JOIN cancel_by_home c USING (policy_id, dwelling_id)
),
claim_home AS (
    SELECT c.policy_id, c.dwelling_id, c.st, c.bh, c.age, c.rse, c.lane,
           c.score, c.model_version, l.claim_id, l.peril, l.loss_date,
           l.paid, l.incurred, l.denied
    FROM coh c INNER JOIN lc l ON l.dwelling_id = c.dwelling_id
    WHERE l.loss_date >= c.bind AND l.loss_date < c.end_exclusive
),
match_audit AS (
    SELECT countIf(matches > 1) AS ambiguous_claims
    FROM (SELECT claim_id, count() AS matches FROM claim_home GROUP BY claim_id)
)

SELECT age_scope, if(peril IN ('Hail','Wind'), 'wind_hail', 'other_perils') AS peril_group,
       rse, lane, count() AS claims, uniqExact(tuple(policy_id,dwelling_id)) AS homes,
       countIf(score IS NOT NULL) AS claims_on_scored_homes,
       quantilesExact(0.25,0.5,0.75,0.9)(paid) AS paid_quantiles,
       max(paid) AS maximum_paid, avg(paid) AS mean_paid,
       quantilesExact(0.25,0.5,0.75,0.9)(incurred) AS incurred_quantiles,
       countIf(paid < 1400) AS paid_below_1400,
       countIf(paid >= 50000) AS paid_at_least_50000,
       countIf(denied = 'true') AS coverage_denied_true,
       countIf(denied IS NULL OR denied NOT IN ('true','')) AS unexpected_denial_value,
       (SELECT ambiguous_claims FROM match_audit) AS ambiguous_claims
FROM claim_home
ARRAY JOIN if(age >= 101, ['all_ages', '101plus'], ['all_ages']) AS age_scope
GROUP BY age_scope, peril_group, rse, lane
ORDER BY age_scope, peril_group, rse, lane;
