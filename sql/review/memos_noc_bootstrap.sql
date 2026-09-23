-- RUN 2026-09-23, completed, one aggregate row: 2000 draws, 1989 valid. Metabase db 235.
-- Purpose: 2000 stratified policy bootstrap draws for the issue-clock NOC transaction A/E.
-- Claims: N3 A30 A34. Expected if memo were exact: point A/E near1.59; a fixed-expected CI is too narrow.
-- Policy is the resampling unit. Resample with replacement within decade/state/issue-half/lane cells.
-- This conditions on observed cell counts; it does not capture changing cell mix or surveillance bias.
-- Each selected policy contributes its events and exposure together; both hand and none are resampled.
-- Keep only cells with baseline control exposure>0 and hand exposure>0; report unmatched separately.
-- Historical creation cohort Jan2024-Jun2026, age at issue101+,first-term365d/Aug20 censor.
-- Original timestamp conventions retained to match the prior independent cells; timezone sensitivity remains.
-- Only aggregate point estimates and percentile intervals leave the warehouse.
WITH first_nb AS (
 SELECT policy_id,argMin(quote_id,tuple(quote_issued_timestamp,quote_id)) AS issued_quote
 FROM dbt.ipod_standard_mga_raw_policy_info
 WHERE quote_type='NewBusiness' AND quote_status='Issued' AND quote_issued_timestamp IS NOT NULL
 GROUP BY policy_id
), coh AS (
 SELECT p.policy_id,min(toDate(p.pol_created_timestamp)) AS created,
 min(toDate(p.quote_issued_timestamp)) AS issued,
 max(toYear(p.quote_issued_timestamp)-p.pol_prop_year_built) AS issue_age,
 max(toYear(p.pol_created_timestamp)-p.pol_prop_year_built) AS creation_age,
 max(p.prop_cov_roof_surfacing_exclusion='selected') AS rse,
 max(p.prop_cov_roof_surfacing_exclusion='selected' AND p.pol_ff_automated_roof_exclusion='yes' AND p.pol_prop_steadily_roof_condition_score_decision='exclude') AS auto,
 groupUniqArray(p.pol_prop_state) AS states
 FROM dbt.ipod_standard_mga_raw_policy_info AS p INNER JOIN first_nb AS n ON p.policy_id=n.policy_id AND p.quote_id=n.issued_quote
 WHERE p.quote_type='NewBusiness' AND p.quote_status='Issued'
 AND p.pol_created_timestamp>=toDateTime('2024-01-01 00:00:00')
 AND p.pol_created_timestamp<toDateTime('2026-07-01 00:00:00') AND p.pol_prop_year_built>1700
 GROUP BY p.policy_id
), first_cancel AS (
 SELECT policy_id,min(toDate(quote_issued_timestamp)) AS cancelled,
 argMin(cancellation_reason,tuple(quote_issued_timestamp,quote_id)) AS reason
 FROM dbt.ipod_standard_mga_raw_policy_info
 WHERE quote_type='Cancellation' AND quote_status='Issued'
 AND quote_issued_timestamp<toDateTime('2026-08-21 00:00:00') GROUP BY policy_id
), j AS (
 SELECT c.policy_id,if(length(c.states)=1,c.states[1],'MULTI_STATE') AS state,
 concat(toString(toYear(c.issued)),'H',toString(if(toMonth(c.issued)<=6,1,2))) AS issue_half,
 multiIf(c.issue_age>=101,concat(toString(101+10*intDiv(c.issue_age-101,10)),'-',toString(110+10*intDiv(c.issue_age-101,10))),c.issue_age>=91,'91-100','90_under') AS age_band,
 multiIf(c.auto,'auto',c.rse,'hand','none') AS lane,
 greatest(0,least(dateDiff('day',c.issued,toDate('2026-08-20')),365,
 if(f.cancelled>=c.issued,dateDiff('day',c.issued,f.cancelled),365))) AS exposure_days,
 f.reason='Inspection' AND f.cancelled>=c.issued
 AND f.cancelled<=least(c.issued+INTERVAL 365 DAY,toDate('2026-08-20')) AS inspection_cancel
 FROM coh c LEFT JOIN first_cancel f ON c.policy_id=f.policy_id
)
, policy_index AS (
 SELECT age_band,state,issue_half,lane,policy_id,exposure_days,
 coalesce(inspection_cancel,0) AS events,
 row_number() OVER (PARTITION BY age_band,state,issue_half,lane ORDER BY policy_id) AS idx,
 count() OVER (PARTITION BY age_band,state,issue_half,lane) AS n
 FROM j WHERE age_band NOT IN ('90_under','91-100') AND lane IN ('hand','none')
), baseline_cells AS (
 SELECT age_band,state,issue_half,lane,count() AS policies,
 sum(exposure_days) AS days,sum(events) AS events FROM policy_index
 GROUP BY age_band,state,issue_half,lane
), support AS (
 SELECT age_band,state,issue_half,
 sumIf(days,lane='none') AS none_days,sumIf(days,lane='hand') AS hand_days
 FROM baseline_cells GROUP BY age_band,state,issue_half
 HAVING none_days>0 AND hand_days>0
), draws AS (
 SELECT p.age_band AS age_band,p.state AS state,p.issue_half AS issue_half,p.lane AS lane,
 arrayJoin(range(2000)) AS draw,
 1+cityHash64(p.policy_id,toString(draw),'roof-review-2026-09-23')%p.n AS sampled_idx
 FROM policy_index p INNER JOIN support s
 ON p.age_band=s.age_band AND p.state=s.state AND p.issue_half=s.issue_half
), replicate_cells AS (
 SELECT d.draw AS draw,d.age_band AS age_band,d.state AS state,d.issue_half AS issue_half,d.lane AS lane,
 sum(p.exposure_days) AS days,sum(p.events) AS events
 FROM draws d INNER JOIN policy_index p
 ON d.age_band=p.age_band AND d.state=p.state AND d.issue_half=p.issue_half AND d.lane=p.lane AND d.sampled_idx=p.idx
 GROUP BY d.draw,d.age_band,d.state,d.issue_half,d.lane
), paired AS (
 SELECT draw,age_band,state,issue_half,
 sumIf(days,lane='hand') AS hand_days,sumIf(events,lane='hand') AS actual,
 sumIf(days,lane='none') AS none_days,sumIf(events,lane='none') AS none_events
 FROM replicate_cells GROUP BY draw,age_band,state,issue_half
), estimates AS (
 SELECT draw,sum(actual) AS actual_events,
 sum(hand_days*none_events/nullIf(none_days,0)) AS expected_events,
 countIf(none_days<=0) AS zero_control_exposure_cells,
 actual_events/nullIf(expected_events,0) AS ratio
 FROM paired GROUP BY draw
), point AS (
 SELECT sumIf(b.events,b.lane='hand') AS actual,
 sumIf(b.days,b.lane='hand')/365.25 AS hand_policy_years
 FROM baseline_cells b INNER JOIN support s
 ON b.age_band=s.age_band AND b.state=s.state AND b.issue_half=s.issue_half
)
SELECT count() AS replicates,
 countIf(zero_control_exposure_cells=0 AND expected_events>0) AS valid_replicates,
 quantilesExactIf(0.025,0.5,0.975)(ratio,zero_control_exposure_cells=0 AND expected_events>0) AS ratio_percentiles,
 quantilesExactIf(0.025,0.5,0.975)(expected_events,zero_control_exposure_cells=0 AND expected_events>0) AS expected_percentiles,
 (SELECT actual FROM point) AS point_actual_events,
 (SELECT hand_policy_years FROM point) AS point_hand_policy_years
FROM estimates;
