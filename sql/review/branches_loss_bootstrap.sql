-- RUN 2026-09-23: 10-draw Poisson preflight returned 2 aggregate rows.
-- 2000-draw final run attempted 2026-09-23; result not retrieved before tool delivery limit.
-- At 2026-09-23 17:36:30 UTC, backend active at 347.6 seconds with 4.81 GB memory.
-- No final CI claimed.
-- Preflight quantiles are NOT reportable confidence intervals.
-- SELECT only; Metabase db 235 / ClickHouse.
-- Purpose: L3/L4/L10/L13/L15, A31/A36. Policy-clustered uncertainty for count and
-- dollar A/Es, control-netted paid ratio, and dollars per excluded home-year.
-- Expected historical point ratios: wind/hail paid A/E 0.1301, other 0.7696,
-- netted ratio 0.1690; historical avoided paid difference about $51.8/home-year.
-- No CI was supplied in the memo. This query supplies one after exposure repair.
-- It re-estimates BOTH the non-excluded cell rates and excluded exposure each draw.
-- Policy-cluster Poisson(1) bootstrap, deterministic hash seed, preserving a common
-- weight for all homes and claims of each policy in each draw. This is an asymptotic
-- bootstrap; total policy weight varies by draw. Run replicates=2000.
-- A fixed-size array sampler failed at 10 draws with MEMORY_LIMIT_EXCEEDED.
-- This replacement streams home x draw rows and returns aggregates only.
-- It does not remove confounding or turn a descriptive difference into a causal saving.
-- Required read-only parameter: claims_data_through, the last covered loss date.
-- Proposed parameter from 2026-09-23 checks: claims_data_through=2026-08-31. Metadata identifies
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
home_loss AS (
    SELECT policy_id,dwelling_id,
           if(peril IN ('Hail','Wind'),'wind_hail','other_perils') AS peril_group,
           count() AS claims,sum(ch.paid) AS paid,sum(ch.incurred) AS incurred,
           sum(least(ch.paid,50000)) AS paid50,sum(least(ch.incurred,50000)) AS incurred50
    FROM claim_home AS ch GROUP BY policy_id,dwelling_id,peril_group
),
homes AS (
    SELECT c.policy_id AS policy_id,c.dwelling_id AS dwelling_id,c.st AS st,
           c.bh AS bh,c.age AS age,c.rse AS rse,c.exp_days AS exp_days,
           g.peril_group AS peril_group,
           coalesce(l.claims,0) AS claims,coalesce(l.paid,0) AS paid,
           coalesce(l.incurred,0) AS incurred,coalesce(l.paid50,0) AS paid50,
           coalesce(l.incurred50,0) AS incurred50
    FROM coh c
    CROSS JOIN (SELECT arrayJoin(['wind_hail','other_perils']) AS peril_group) g
    LEFT JOIN home_loss l ON l.policy_id=c.policy_id AND l.dwelling_id=c.dwelling_id
                         AND l.peril_group=g.peril_group
),
weighted_homes AS (
    SELECT *,arrayFirstIndex(z -> u < z, [0.36787944117144233,0.7357588823428847,0.9196986029286058,0.9810118431238463,0.9963401531726563,0.9994058151824183,0.999916758850712,0.9999897508033254,0.999998874797402,0.9999998885745217,0.9999999899522337,0.9999999991683893,0.9999999999364023,0.9999999999954802,0.9999999999997,0.9999999999999813,0.9999999999999989,1.0,1.0,1.0,1.0]) - 1 AS weight
    FROM (
      SELECT h.*,reps.number AS replica,
             (cityHash64(h.policy_id,toString(reps.number),'roof-loss-bootstrap-2026-09-23')
                % 9007199254740992) / 9007199254740992.0 AS u
      FROM homes h CROSS JOIN numbers({replicates:UInt32}) reps
    ) draws
),
cells AS (
    SELECT h.replica,age_scope,h.st,h.bh,h.rse,h.peril_group,
           sum(h.exp_days*h.weight)/365.25 AS dy,
           sum(h.claims*h.weight) AS claims,sum(h.paid*h.weight) AS paid,
           sum(h.incurred*h.weight) AS incurred,sum(h.paid50*h.weight) AS paid50,
           sum(h.incurred50*h.weight) AS incurred50
    FROM weighted_homes h
    ARRAY JOIN if(h.age>=101,['all_ages','101plus'],['all_ages']) AS age_scope
    GROUP BY h.replica,age_scope,h.st,h.bh,h.rse,h.peril_group
),
ae AS (
    SELECT r.replica,r.age_scope,r.peril_group,
           sumIf(r.dy,n.dy>0) AS dy, coalesce(sumIf(r.dy,coalesce(n.dy,0)<=0),0) AS unmatched_dy,
           sumIf(r.claims,n.dy>0)/nullIf(sum(r.dy*n.claims/nullIf(n.dy,0)),0) AS claim_ae,
           sumIf(r.paid,n.dy>0) AS actual_paid,
           sum(r.dy*n.paid/nullIf(n.dy,0)) AS expected_paid,
           sumIf(r.incurred,n.dy>0)/nullIf(sum(r.dy*n.incurred/nullIf(n.dy,0)),0) AS incurred_ae,
           sumIf(r.paid50,n.dy>0)/nullIf(sum(r.dy*n.paid50/nullIf(n.dy,0)),0) AS paid50_ae,
           sumIf(r.incurred50,n.dy>0)/nullIf(sum(r.dy*n.incurred50/nullIf(n.dy,0)),0) AS incurred50_ae
    FROM (SELECT * FROM cells WHERE rse=1) r
    LEFT JOIN (SELECT * FROM cells WHERE rse=0 AND dy>0) n
      ON n.replica=r.replica AND n.age_scope=r.age_scope AND n.st=r.st
     AND n.bh=r.bh AND n.peril_group=r.peril_group
    GROUP BY r.replica,r.age_scope,r.peril_group
),
ratios AS (
 SELECT *,actual_paid/nullIf(expected_paid,0) AS paid_ae FROM ae
)
SELECT r.age_scope,count() AS bootstrap_draws,
       countIf(r.expected_paid>0 AND c.paid_ae>0) AS valid_netted_draws,
       max(r.unmatched_dy) AS maximum_unmatched_wind_hail_dy,
       quantilesExact(0.025,0.5,0.975)(r.claim_ae) AS wind_hail_count_ae_interval,
       quantilesExact(0.025,0.5,0.975)(r.paid_ae) AS wind_hail_paid_ae_interval,
       quantilesExact(0.025,0.5,0.975)(c.paid_ae) AS control_paid_ae_interval,
       quantilesExact(0.025,0.5,0.975)(r.paid_ae/nullIf(c.paid_ae,0)) AS netted_paid_ratio_interval,
       quantilesExact(0.025,0.5,0.975)((c.paid_ae*r.expected_paid-r.actual_paid)/nullIf(r.dy,0)) AS paid_difference_per_home_year_interval,
       quantilesExact(0.025,0.5,0.975)(r.incurred_ae/nullIf(c.incurred_ae,0)) AS netted_incurred_interval,
       quantilesExact(0.025,0.5,0.975)(r.paid50_ae/nullIf(c.paid50_ae,0)) AS netted_paid_cap50k_interval,
       quantilesExact(0.025,0.5,0.975)(r.incurred50_ae/nullIf(c.incurred50_ae,0)) AS netted_incurred_cap50k_interval,
       (SELECT ambiguous_claims FROM match_audit) AS ambiguous_claims
FROM (SELECT * FROM ratios WHERE peril_group='wind_hail') r
INNER JOIN (SELECT * FROM ratios WHERE peril_group='other_perils') c
 ON c.replica=r.replica AND c.age_scope=r.age_scope
GROUP BY r.age_scope ORDER BY r.age_scope;
