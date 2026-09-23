-- RUN 2026-09-23, database 235, SELECT only. L6 A22. Isolate join duplication using the original creation clock and July 31 censor; live source data. Returned 2 aggregate rows. NOT a corrected effective-date estimate.
-- Expected if original definitions agree: zero date mismatches / zero exposure inflation.
WITH lc AS (
 SELECT claim_id,argMax(tuple(dwelling_id),toDate(concat(splitByChar('-',claims_file)[2],'-',leftPad(splitByChar('-',claims_file)[1],2,'0'),'-01'))) AS r
 FROM dbt.claims_smga GROUP BY claim_id
), counts AS (SELECT r.1 AS dwelling_id,count() AS claims FROM lc WHERE r.1 IS NOT NULL AND r.1!='' GROUP BY r.1),
coh AS (
 SELECT policy_id,dwelling_id,prop_cov_roof_surfacing_exclusion='selected' AS rse,
 least(dateDiff('day',toDate(pol_created_timestamp),toDate('2026-07-31')),365) AS exp_days
 FROM dbt.ipod_standard_mga_raw_policy_info WHERE quote_type='NewBusiness' AND quote_status='Issued'
 AND pol_created_timestamp>=toDateTime('2024-01-01 00:00:00') AND pol_created_timestamp<toDateTime('2026-07-01 00:00:00') AND pol_prop_year_built>1700)
SELECT rse,count() AS homes,countIf(claims>1) AS multi_claim_homes,sum(exp_days)/365.25 AS correct_separate_dy,
sum(exp_days*greatest(coalesce(claims,0),1))/365.25 AS after_claim_join_dy,
after_claim_join_dy-correct_separate_dy AS excess_dy,
100*(after_claim_join_dy/correct_separate_dy-1) AS inflation_pct
FROM coh LEFT JOIN counts USING(dwelling_id) GROUP BY rse ORDER BY rse;
