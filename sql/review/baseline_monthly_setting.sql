-- RUN 2026-09-23. Completed SELECTs; returned rows per statement: 993.
-- Purpose: One denominator for monthly current setting, decision-score span and launch hygiene.
-- Claim IDs: S1 S2 S3 S14 S27 S28 S29 RS31 RS32 RS33 RS34 A13 A15 A18
-- Expected if the first read is right: 59/5481=1.08% bound 101+ dwelling signature, not 4% referrals. Aug flag-on hand=83, projected 166/mo, not 174 ex-holdout.
-- Output is aggregate only. Live current rows cannot restore an earlier warehouse snapshot.

WITH base AS (
 SELECT *, toStartOfMonth(pol_created_timestamp) AS creation_month,
        multiIf(2026-pol_prop_year_built>=101,'101+',2026-pol_prop_year_built>=91,'91-100','80-90') AS age_band,
        multiIf(prop_cov_roof_surfacing_exclusion = 'selected' AND pol_ff_automated_roof_exclusion = 'yes' AND pol_prop_steadily_roof_condition_score_decision = 'exclude', 'auto', prop_cov_roof_surfacing_exclusion = 'selected', 'hand', 'none') AS lane,
        if(pol_prop_state IN ('AZ','NJ'),toDate('2026-04-21'),
          if(pol_prop_state IN ('TN','PA','NC'),toDate('2026-04-30'),
            if(pol_prop_state IN ('CA','TX'),toDate('2026-05-11'),toDate('2026-07-30')))) AS wave_date,
        toDate(pol_created_timestamp) NOT IN (toDate('2026-04-27'),toDate('2026-04-28'),toDate('2026-05-29')) AS hygiene_ok
 FROM dbt.ipod_standard_mga_raw_policy_info
 WHERE quote_type='NewBusiness' AND pol_created_timestamp>=toDateTime('2026-04-01')
 AND pol_created_timestamp<toDateTime('2026-08-16')
 AND pol_prop_year_built>1700 AND 2026-pol_prop_year_built>=80
)
SELECT creation_month,age_band,pol_prop_state AS state,hygiene_ok,
       toDate(pol_created_timestamp)>=wave_date AS post_wave,
       count() AS quote_home_rows,uniqExact(quote_id) AS quotes,
       countIf(quote_status='Issued') AS issued_homes,
       countIf(lane='auto') AS auto_signature_all_homes,
       countIf(lane='auto' AND quote_status='Issued') AS issued_auto_homes,
       countIf(lane='hand' AND quote_status='Issued') AS issued_hand_homes,
       countIf(lane='hand' AND quote_status='Issued' AND pol_ff_automated_roof_exclusion='yes') AS issued_hand_flag_on,
       countIf(lane='hand' AND quote_status='Issued' AND pol_ff_automated_roof_exclusion!='yes') AS issued_hand_flag_off,
       countIf(pol_prop_steadily_roof_condition_score_decision='exclude') AS exclude_decision_rows,
       countIf(pol_prop_steadily_roof_condition_score_decision='exclude' AND pol_ff_automated_roof_exclusion='yes') AS flag_on_exclude_decision_rows,
       minIf(pol_prop_steadily_roof_condition_score_condition_score,pol_prop_steadily_roof_condition_score_decision='exclude') AS exclude_min_score,
       maxIf(pol_prop_steadily_roof_condition_score_condition_score,pol_prop_steadily_roof_condition_score_decision='exclude') AS exclude_max_score
FROM base GROUP BY creation_month,age_band,state,hygiene_ok,post_wave
ORDER BY creation_month,age_band,state;
-- Proposed monthly setting: auto_signature_homes / all quote homes, 101+ home age at
-- creation, v1.2.0 decision-time eligible traffic in deployable states. This query gives
-- current-row inputs only. Signature is not actor attribution and raw rows need grain check.
-- For history, keep all rows; for event studies require hygiene_ok and state-specific wave.
-- Texas zero selected exclusions does not prove zero exclude decisions. Inspect both columns.
-- LD segment/form availability remain blocked until the schema dependency check is resolved.
