-- RUN 2026-09-23. Completed SELECTs; returned rows per statement: 32.
-- Purpose: Separate 80+/101+ projected August, bound-book and current-routing proxy compliance bases.
-- Claim IDs: S3 S28 RS4 RS34 RS35 R2
-- Expected if the first read is right: Historical 101+ Aug raw hand=87, flag-on=83; 35%*98=34.3 dwellings/mo only if transferred 80+ share holds, which is untested.
-- Output is aggregate only. Live current rows cannot restore an earlier warehouse snapshot.

WITH alerts AS (
 SELECT quote_id,max(toUInt8(requires_uw_review)) AS required
 FROM dbt_upc.uw_alerts_per_quote
 WHERE alert_category NOT IN ('DATA_SAFEGUARD','VALIDATION','SHOWSTOPPER','SYSTEM_ERROR') GROUP BY quote_id
), refs AS (
 SELECT DISTINCT JSONExtractString(data,'quote_id') AS quote_id
 FROM raw_pg_eventstore.eventstore_good_events
 WHERE name='underwriting_review_note' AND JSONExtractString(data,'action')='uw_note_submitted_and_review_requested'
 AND JSONExtractString(data,'category')='underwriting_review'
 AND created_at>=toDateTime('2026-03-01') AND created_at<toDateTime('2026-08-21')
), base AS (
 SELECT p.*, multiIf(prop_cov_roof_surfacing_exclusion = 'selected' AND pol_ff_automated_roof_exclusion = 'yes' AND pol_prop_steadily_roof_condition_score_decision = 'exclude', 'auto', prop_cov_roof_surfacing_exclusion = 'selected', 'hand', 'none') AS lane, coalesce(a.required,0) AS alert_required,
        p.quote_id IN (SELECT quote_id FROM refs) AS referred,
        arrayJoin(['80+','101+']) AS age_cut,
        arrayJoin([80,85]) AS bar,
        arrayJoin(['all_states','ex_CO_RI_WV']) AS state_cut
 FROM dbt.ipod_standard_mga_raw_policy_info p LEFT JOIN alerts a ON a.quote_id=p.quote_id
 WHERE quote_type='NewBusiness' AND quote_status='Issued'
 AND pol_created_timestamp>=toDateTime('2026-05-01') AND pol_created_timestamp<toDateTime('2026-08-16')
 AND pol_prop_year_built>1700 AND 2026-pol_prop_year_built>=80
 AND (age_cut='80+' OR 2026-pol_prop_year_built>=101)
 AND (state_cut='all_states' OR pol_prop_state NOT IN ('CO','RI','WV'))
)
SELECT toStartOfMonth(pol_created_timestamp) AS creation_month,age_cut,state_cut,bar,
       countIf(lane='hand') AS hand_homes,
       countIf(lane='hand' AND pol_ff_automated_roof_exclusion='yes') AS hand_flag_on_homes,
       countIf(lane='auto') AS auto_homes,
       countIf(lane='hand' AND pol_prop_steadily_roof_condition_score_condition_score>=bar) AS catches,
       countIf(lane='none' AND pol_prop_steadily_roof_condition_score_condition_score>=bar) AS over_homes,
       countIf(lane='none' AND pol_prop_steadily_roof_condition_score_condition_score>=bar AND alert_required=0) AS no_alert_over_homes,
       countIf(lane='none' AND pol_prop_steadily_roof_condition_score_condition_score>=bar AND alert_required=0 AND referred=0) AS no_alert_no_submission_over_homes,
       uniqExactIf(quote_id,lane='none' AND pol_prop_steadily_roof_condition_score_condition_score>=bar AND alert_required=0 AND referred=0) AS no_alert_no_submission_over_quotes,
       countIf(pol_prop_steadily_roof_condition_score_condition_score>=bar) AS pass_through_candidate_homes,
       uniqExactIf(quote_id,pol_prop_steadily_roof_condition_score_condition_score>=bar) AS pass_through_candidate_quotes
FROM base GROUP BY creation_month,age_cut,state_cut,bar ORDER BY creation_month,age_cut,state_cut,bar;
-- May-Aug15 totals / 3.5 are the historical bound-book convention; Aug1-15 *2 is
-- a censored projection, not a floor or fixed issued-month pace. July/Aug ratios must
-- use the same age/state/lane and maturation definition. requires_uw_review is no visit.
-- Pass-through outputs give pre-attestation candidate counts under PRD routing; they
-- are NOT final exclusions, letters sent, legal compliance events or incremental binds.
