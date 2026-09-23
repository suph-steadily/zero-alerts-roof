-- RUN 2026-09-23, database 235, SELECT only; 4 aggregate rows; claims_data_through=2026-08-31; explicit America/Chicago.
-- Public output is aggregate only. Never export identifiers from these CTEs.
-- Purpose: L1/L3/L4/L5/L6/L8/L10/L15/L16, A22/A28/A31/A36/A41/A43.
-- Expected if the old memo is reproduced: excluded 3,905 home-years, 25 wind/hail
-- claims, $41,152 paid vs $316,333 expected; 46 other claims and $641,073/$833,011.
-- Those are historical ALL-AGE totals for Jan 2024-Jun 2026 creations, censored
-- July 31 in the old SQL. The corrected totals can differ and must be reported anew.
-- Grain: one issued (policy, dwelling), age = effective-start year minus year_built > 1700.
-- Exposure is aggregated BEFORE the claim join. Show both all ages and 101+.
-- Non-overlapping [bind, end_exclusive) windows; a cancellation stops at that date.
-- No reinstated exposure is re-added: report this first-spell estimand explicitly.
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
    FROM (SELECT claim_id, count() AS matches FROM claim_home AS ch GROUP BY claim_id)
)
,
exposure_cells AS (
    SELECT age_scope, st, bh, rse, count() AS homes, sum(exp_days) / 365.25 AS dy
    FROM coh ARRAY JOIN if(age >= 101, ['all_ages', '101plus'], ['all_ages']) AS age_scope
    GROUP BY age_scope, st, bh, rse
),
loss_cells AS (
    SELECT age_scope, st, bh, rse,
           if(peril IN ('Hail','Wind'), 'wind_hail', 'other_perils') AS peril_group,
           count() AS claims, sum(ch.paid) AS paid, sum(ch.incurred) AS incurred,
           sum(least(ch.paid, 50000)) AS paid_capped_50k,
           sum(least(ch.incurred, 50000)) AS incurred_capped_50k
    FROM claim_home AS ch
    ARRAY JOIN if(age >= 101, ['all_ages', '101plus'], ['all_ages']) AS age_scope
    GROUP BY age_scope, st, bh, rse, peril_group
),
cells AS (
    SELECT e.age_scope AS age_scope, e.st AS st, e.bh AS bh, e.rse AS rse,
           e.homes AS homes, e.dy AS dy, g.peril_group AS peril_group,
           coalesce(l.claims, 0) AS claims, coalesce(l.paid, 0) AS paid,
           coalesce(l.incurred, 0) AS incurred,
           coalesce(l.paid_capped_50k, 0) AS paid_capped_50k,
           coalesce(l.incurred_capped_50k, 0) AS incurred_capped_50k
    FROM exposure_cells e
    CROSS JOIN (SELECT arrayJoin(['wind_hail','other_perils']) AS peril_group) g
    LEFT JOIN loss_cells l ON l.age_scope=e.age_scope AND l.st=e.st AND l.bh=e.bh
                         AND l.rse=e.rse AND l.peril_group=g.peril_group
)
SELECT r.age_scope, r.peril_group,
       sum(r.homes) AS excluded_homes, sum(r.dy) AS excluded_home_years,
       sumIf(r.dy, n.dy > 0) AS matched_excluded_home_years,
       coalesce(sumIf(r.dy, coalesce(n.dy,0) <= 0),0) AS unmatched_excluded_home_years,
       sum(n.dy) AS comparator_home_years_in_matched_cells,
       sumIf(r.claims, n.dy > 0) AS actual_claims,
       sum(r.dy * n.claims / nullIf(n.dy, 0)) AS expected_claims,
       sumIf(r.paid, n.dy > 0) AS actual_paid,
       sum(r.dy * n.paid / nullIf(n.dy, 0)) AS expected_paid,
       sumIf(r.incurred, n.dy > 0) AS actual_incurred,
       sum(r.dy * n.incurred / nullIf(n.dy, 0)) AS expected_incurred,
       sumIf(r.paid_capped_50k, n.dy > 0) AS actual_paid_capped_50k,
       sum(r.dy * n.paid_capped_50k / nullIf(n.dy, 0)) AS expected_paid_capped_50k,
       sumIf(r.incurred_capped_50k, n.dy > 0) AS actual_incurred_capped_50k,
       sum(r.dy * n.incurred_capped_50k / nullIf(n.dy, 0)) AS expected_incurred_capped_50k,
       (SELECT ambiguous_claims FROM match_audit) AS ambiguous_claims,
       (SELECT file_month FROM latest_file) AS latest_claims_file_month,
       {claims_data_through:Date} AS confirmed_claims_data_through
FROM (SELECT * FROM cells WHERE rse=1) r
LEFT JOIN (SELECT * FROM cells WHERE rse=0 AND dy>0) n
  ON n.age_scope=r.age_scope AND n.st=r.st AND n.bh=r.bh AND n.peril_group=r.peril_group
GROUP BY r.age_scope, r.peril_group
ORDER BY r.age_scope, r.peril_group;
