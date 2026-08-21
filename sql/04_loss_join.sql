-- 04_loss_join.sql  (Metabase db 235, ClickHouse; read-only)
-- Answers the memo's open item: "is our exposure reduced or only moved into the
-- contract, which needs the loss join."  Run 2026-08-21.
--
-- Claims source: dbt.claims_smga.  Facts verified this run:
--   * 86,317 rows = 7,278 distinct claim_id.  claims_file ('M-YYYY') is a MONTHLY
--     CUMULATIVE SNAPSHOT, so a claim repeats once per file it appears in.
--     ALWAYS dedupe to the latest file per claim or every count is ~12x inflated.
--     Sorting claims_file as a STRING is wrong ('9-2025' > '8-2026'); parse it.
--   * dwelling_id is the bare ipod dwelling uuid -> joins straight to
--     ipod_standard_mga_raw_policy_info.dwelling_id.  Only 140 rows lack it.
--   * standardized_loss_type is the clean peril column.  DEDUPED book-wide: Hail is
--     the #1 loss type by claim count (2,022 claims, $21.9M paid), Water Damage #2
--     (1,906, $19.3M), Wind #3 (1,355, $15.5M); Fire is only 292 claims but the
--     largest single bucket by dollars ($33.3M).  Wind+Hail = 46% of all claims and
--     are the roof-surfacing perils; everything else is the control group.
--     (Summing total_paid WITHOUT deduping inflates every dollar figure ~12x.)
--   * coverage_denied is 'true' / '' (blank), NOT a bool.
--
-- Design: first-term exposure only (capped 365 days from bind), so a young 2026
-- cohort is not compared against a matured 2024 one.  Expected loss is built by
-- DIRECT STANDARDISATION on state x bind-half-year cells: each cell's
-- non-excluded rate is applied to the excluded book's own exposure.  State
-- controls hail geography (the excluded book is under-weighted in TX: 4.3% of
-- excluded dwellings vs 12.6% of the rest); bind-half controls calendar time and
-- therefore claim development.
--
-- LIMITS: n = 25 excluded wind/hail claims.  'Excluded' is read off the issued NB
-- quote row, so exclusions added later by endorsement sit in the control group
-- (dilutes the control, biases the measured effect DOWNWARD).  total_paid is
-- undeveloped on recent claims for both groups.  Selection is not random -- an
-- underwriter chose these roofs -- but that biases toward MORE expected roof
-- loss, so it is conservative for the direction found here.

WITH lc AS (
    -- one row per claim: the latest monthly snapshot
    SELECT claim_id, dwelling_id,
           standardized_loss_type AS lt,
           loss_date, total_paid, total_incurred, coverage_denied
    FROM dbt.claims_smga
    WHERE dwelling_id IS NOT NULL AND dwelling_id != ''
    ORDER BY toDate(concat(splitByChar('-', claims_file)[2], '-',
                           leftPad(splitByChar('-', claims_file)[1], 2, '0'), '-01')) DESC
    LIMIT 1 BY claim_id
),
coh AS (
    SELECT dwelling_id,
           toDate(pol_created_timestamp) AS bind,
           pol_prop_state              AS st,
           concat(toString(toYear(pol_created_timestamp)), 'H',
                  toString(if(toMonth(pol_created_timestamp) <= 6, 1, 2))) AS bh,
           if(prop_cov_roof_surfacing_exclusion = 'selected', 1, 0) AS rse,
           least(dateDiff('day', toDate(pol_created_timestamp), toDate('2026-07-31')), 365) AS exp_days
    FROM dbt.ipod_standard_mga_raw_policy_info
    WHERE quote_type = 'NewBusiness'
      AND quote_status = 'Issued'
      AND pol_created_timestamp >= toDateTime('2024-01-01 00:00:00')
      AND pol_created_timestamp <  toDateTime('2026-07-01 00:00:00')
      AND pol_prop_year_built > 1700
),
cells AS (
    SELECT c.st AS st, c.bh AS bh, c.rse AS rse,
           sum(c.exp_days) / 365.25 AS dy,
           uniqExactIf(l.claim_id, l.lt IN ('Hail','Wind')
                       AND l.loss_date >= c.bind AND l.loss_date <= c.bind + c.exp_days) AS whc,
           sumIf(l.total_paid, l.lt IN ('Hail','Wind')
                 AND l.loss_date >= c.bind AND l.loss_date <= c.bind + c.exp_days) AS whp,
           uniqExactIf(l.claim_id, l.lt NOT IN ('Hail','Wind')
                       AND l.loss_date >= c.bind AND l.loss_date <= c.bind + c.exp_days) AS oc,
           sumIf(l.total_paid, l.lt NOT IN ('Hail','Wind')
                 AND l.loss_date >= c.bind AND l.loss_date <= c.bind + c.exp_days) AS op
    FROM coh AS c
    LEFT JOIN lc AS l ON l.dwelling_id = c.dwelling_id
    GROUP BY st, bh, rse
)
SELECT round(sum(r.dy))                              AS matched_dwelling_years,
       sum(r.whc)                                    AS act_wind_hail_claims,
       round(sum(r.dy * n.whc / n.dy), 1)            AS exp_wind_hail_claims,
       round(sum(r.whp))                             AS act_wind_hail_paid,
       round(sum(r.dy * n.whp / n.dy))               AS exp_wind_hail_paid,
       sum(r.oc)                                     AS act_control_claims,
       round(sum(r.dy * n.oc  / n.dy), 1)            AS exp_control_claims,
       round(sum(r.op))                              AS act_control_paid,
       round(sum(r.dy * n.op  / n.dy))               AS exp_control_paid
FROM      (SELECT * FROM cells WHERE rse = 1)            AS r
INNER JOIN(SELECT * FROM cells WHERE rse = 0 AND dy > 0) AS n
       ON n.st = r.st AND n.bh = r.bh;

-- 2026-08-21 result: 3,905 dy | claims 25 vs 31.3 exp | paid $41,152 vs $316,333 exp
--                    control  46 vs 51.1 exp | paid $641,073 vs $833,011 exp
--
-- ---------------------------------------------------------------------------
-- Companion query: the severity distribution and the development-matched sign
-- test (each excluded claim against its OWN loss-quarter non-excluded median).
-- Swap the final SELECT above for this one.
--
-- ), j AS (
--     SELECT c.rse AS rse, toStartOfQuarter(l.loss_date) AS lq, l.total_paid AS paid,
--            l.coverage_denied AS den, l.claim_desc_of_loss AS dsc
--     FROM coh AS c INNER JOIN lc AS l ON l.dwelling_id = c.dwelling_id
--     WHERE l.lt IN ('Hail','Wind')
--       AND l.loss_date >= c.bind AND l.loss_date <= c.bind + c.exp_days
-- ),
-- med AS (SELECT lq, quantileExact(0.5)(paid) AS m FROM j WHERE rse = 0 GROUP BY lq)
-- SELECT (SELECT count()                FROM j r INNER JOIN med m ON m.lq = r.lq WHERE r.rse = 1) AS n_matched,
--        (SELECT countIf(r.paid < m.m)  FROM j r INNER JOIN med m ON m.lq = r.lq WHERE r.rse = 1) AS below_quarter_median,
--        (SELECT round(100.0*countIf(den != '')/count(), 1) FROM j WHERE rse = 1) AS excl_denied_pct,
--        (SELECT round(100.0*countIf(den != '')/count(), 1) FROM j WHERE rse = 0) AS ctrl_denied_pct;
--
-- 2026-08-21 result: 22 of 25 below their own quarter's median (one-sided p = 7.8e-05);
--                    coverage_denied 16.0% excluded vs 3.1% not.
