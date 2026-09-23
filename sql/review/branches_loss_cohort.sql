-- RUN 2026-09-23, database 235, SELECT only; two statements returned 1 and 2 aggregate rows; explicit America/Chicago.
-- Purpose: L5/L6/L8, A22/A28/A40/A43. Establish grain and source cohort totals.
-- Expected historical Jan 2024-Jun 2026 ALL-AGE issued NB cohort: 7,060 excluded
-- dwellings and 250,691 others; TX shares 4.3% vs 12.6%. These were not output by sql/04.
-- Check exact source duplication before selecting an issued tuple. Query 2 is the
-- historical created-date census, not a corrected home-year claim.
WITH keys AS (
 SELECT policy_id,dwelling_id,count() AS rows_per_home,
        uniqExact(quote_id) AS issued_quotes,
        uniqExact(tuple(quote_id,pol_created_timestamp,quote_issued_timestamp,
                  pol_prop_state,pol_prop_year_built,prop_cov_roof_surfacing_exclusion,
                  pol_ff_automated_roof_exclusion,
                  pol_prop_steadily_roof_condition_score_decision)) AS distinct_tuples
 FROM dbt.ipod_standard_mga_raw_policy_info
 WHERE quote_type='NewBusiness' AND quote_status='Issued'
   AND pol_created_timestamp>=toDateTime('2024-01-01 00:00:00','America/Chicago')
   AND pol_created_timestamp<toDateTime('2026-07-01 00:00:00','America/Chicago')
   AND pol_prop_year_built>1700
 GROUP BY policy_id,dwelling_id
)
SELECT count() AS homes, sum(rows_per_home) AS rows_,
       countIf(rows_per_home>1) AS duplicated_home_keys,
       countIf(distinct_tuples>1) AS conflicting_home_keys,
       countIf(issued_quotes>1) AS multi_issued_quote_homes FROM keys;

WITH t AS (
 SELECT policy_id,dwelling_id,
        argMax(tuple(toDate(pol_created_timestamp,'America/Chicago'),toDate(quote_issued_timestamp,'America/Chicago'),
                     pol_prop_state,pol_prop_year_built,prop_cov_roof_surfacing_exclusion,
                     pol_ff_automated_roof_exclusion,
                     pol_prop_steadily_roof_condition_score_decision),
               tuple(quote_issued_timestamp,toString(quote_id))) AS r
 FROM dbt.ipod_standard_mga_raw_policy_info
 WHERE quote_type='NewBusiness' AND quote_status='Issued'
   AND pol_created_timestamp>=toDateTime('2024-01-01 00:00:00','America/Chicago')
   AND pol_created_timestamp<toDateTime('2026-07-01 00:00:00','America/Chicago')
 GROUP BY policy_id,dwelling_id
)
SELECT toUInt8(r.5='selected') AS excluded, count() AS homes,
       uniqExact(policy_id) AS policies, countIf(r.3='TX') AS texas_homes,
       100.0*texas_homes/homes AS texas_share_pct,
       countIf(r.5='selected' AND r.6='yes' AND r.7='exclude') AS inferred_auto_homes,
       uniqExactIf(policy_id,r.5='selected' AND r.6='yes' AND r.7='exclude') AS inferred_auto_policies,
       countIf(toYear(r.2)-r.4>=101) AS age101_at_issue_homes,
       countIf(r.1!=r.2) AS issue_differs_from_creation_homes,
       quantilesExact(0.5,0.9)(dateDiff('day',r.1,r.2)) AS creation_to_issue_days
FROM t WHERE r.4>1700 GROUP BY excluded ORDER BY excluded;
