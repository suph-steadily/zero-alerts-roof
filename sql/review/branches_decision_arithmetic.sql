-- NOT RUN. Static review 2026-09-23. SELECT only; Metabase db 235 / ClickHouse.
-- Purpose: D4/D5/D6/D10/D11/D12/D13/D19/D20. Independently recompute the matrix
-- from repository aggregate counts only. No warehouse data retrieval, no source validation.
-- Expected: same marginal ratios after rounding, baseline add-bar-95 cost 102/227=0.4493
-- if every existing auto exclusion stays and new rule affects only hand/none.
-- 101+ = 2026-year_built, May 1-Aug 15 2026 bound dwelling counts, 3.5 supplied months.
WITH c AS (
 SELECT tupleElement(x,1) AS bar,tupleElement(x,2) AS catches,tupleElement(x,3) AS overs
 FROM (SELECT arrayJoin([(1000,0,0),(95,227,102),(90,394,244),(85,516,429),
                         (83,557,528),(80,618,682),(75,707,927),(70,765,1130),
                         (65,809,1329),(60,843,1552),(55,881,1781)]) AS x)
), d AS (
 SELECT *, lagInFrame(catches,1,0) OVER w AS previous_catches,
           lagInFrame(overs,1,0) OVER w AS previous_overs
 FROM c WINDOW w AS (ORDER BY bar DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
)
SELECT bar,catches,overs,catches/1018.0 AS capture_of_hand,
       catches/3.5 AS catches_per_supplied_month,overs/3.5 AS overs_per_supplied_month,
       (overs-previous_overs)/nullIf(catches-previous_catches,0) AS exact_step_cost,
       59/3.5 AS existing_auto_per_supplied_month,
       59/1077.0 AS auto_share_of_all_exclusions,
       114/(618/3.5) AS august_catch_projection_over_bound_base,
       98/(682/3.5) AS august_over_projection_over_bound_base
FROM d WHERE bar<1000 ORDER BY bar DESC;

-- Maximize total utility across the whole grid. Parameter R is catch value / net
-- incremental over-apply cost; equal value per home is an assumption, not an estimate.
-- This handles nonmonotone costs below 65 and shows indifference at exact boundaries.
WITH c AS (
 SELECT tupleElement(x,1) AS bar,tupleElement(x,2) AS catches,tupleElement(x,3) AS overs
 FROM (SELECT arrayJoin([(1000,0,0),(95,227,102),(90,394,244),(85,516,429),
                         (83,557,528),(80,618,682),(75,707,927),(70,765,1130),
                         (65,809,1329),(60,843,1552),(55,881,1781)]) AS x)
)
SELECT bar, catches, overs, {R:Float64}*catches-overs AS incremental_utility
FROM c ORDER BY incremental_utility DESC,bar DESC;
