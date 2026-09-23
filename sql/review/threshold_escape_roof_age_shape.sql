-- RUN 2026-09-23, completed, 74 aggregate/schema rows. Metabase db 235; SELECT only.
-- Purpose: safely classify stored MGA roof-age representations and material on 101+ quote traffic.
-- Expected: unknown distribution; do not read general remodel year as full roof replacement.
-- Primary cohort July 30-August 31 2026 NB, age at creation 101+, current v1.2.0, CO/RI/WV excluded, Chicago dates.
-- Issued cutoff is before September 23, matching the integer sweep.
-- Current quote-home grain; first checks duplicate keys. No raw roof-age strings or entity IDs are returned.
-- Values 0 and 20 are separate boundary/default candidates. Integer ages above 100 and calendar-looking years are not trusted.
WITH homes AS (
 SELECT quote_id,dwelling_id,count() AS source_rows,
 groupUniqArray(pol_prop_roof_age) AS ages,
 groupUniqArray(pol_prop_roof_type) AS materials_v1,
 groupUniqArray(pol_prop_roof_type_v2) AS materials_v2,
 max(pol_prop_steadily_roof_condition_score_condition_score) AS score,
 max(prop_cov_roof_surfacing_exclusion='selected') AS selected,
 max(prop_cov_roof_surfacing_exclusion='selected' AND pol_ff_automated_roof_exclusion='yes'
 AND pol_prop_steadily_roof_condition_score_decision='exclude') AS auto,
 max(quote_status='Issued' AND quote_issued_timestamp<toDateTime('2026-09-23','America/Chicago')) AS bound
 FROM dbt.ipod_standard_mga_raw_policy_info
 WHERE quote_type='NewBusiness'
 AND pol_created_timestamp>=toDateTime('2026-07-30','America/Chicago')
 AND pol_created_timestamp<toDateTime('2026-09-01','America/Chicago')
 AND pol_prop_year_built>1700
 AND toYear(toTimeZone(pol_created_timestamp,'America/Chicago'))-pol_prop_year_built>=101
 AND pol_prop_state NOT IN ('CO','RI','WV')
 AND pol_prop_steadily_roof_condition_score_model_version='v1.2.0'
 GROUP BY quote_id,dwelling_id
), labelled AS (
 SELECT *,toFloat64OrNull(trimBoth(ages[1])) AS numeric_age,
 multiIf(length(ages)!=1,'conflicting_rows',ages[1]='','blank',numeric_age=0,'zero',
 numeric_age>0 AND numeric_age<20,'numeric_under20_nonzero',numeric_age=20,'numeric_20',
 numeric_age>20 AND numeric_age<=100,'numeric_21_to_100',numeric_age>=1700,'calendar_year_looking',
 numeric_age IS NOT NULL,'other_numeric',
 match(lower(ages[1]),'unknown|unsure|not.?known'),'unknown_token',
 match(ages[1],'[0-9]'),'non_numeric_with_digits','other_non_numeric') AS age_representation,
 lower(if(length(materials_v2)=1 AND materials_v2[1]!='',materials_v2[1],materials_v1[1])) AS material_raw,
 multiIf(match(material_raw,'slate'),'slate',match(material_raw,'tile'),'tile',
 match(material_raw,'metal|tin|aluminum|copper'),'metal',match(material_raw,'asphalt|composition|architectural|impact_resistant'),'asphalt_composition',
 match(material_raw,'wood|shake'),'wood_shake',match(material_raw,'membrane|rubber|epdm|tpo|flat|built'),'flat_membrane',
 material_raw='','blank','other') AS material_group,
 multiIf(auto,'auto',selected,'hand_signature','none') AS lane,
 multiIf(score IS NULL,'unscored',score>=95,'95+',score>=90,'90-94',score>=85,'85-89',score>=83,'83-84',score>=80,'80-82','below80') AS score_band
 FROM homes
)
SELECT score_band,lane,age_representation,material_group,count() AS quote_homes,sum(bound) AS bound_quote_homes,
 countIf(source_rows>1) AS duplicate_key_homes,
 countIf(length(materials_v1)>1 OR length(materials_v2)>1) AS conflicting_material_homes
FROM labelled GROUP BY score_band,lane,age_representation,material_group
ORDER BY score_band,lane,age_representation,material_group;
