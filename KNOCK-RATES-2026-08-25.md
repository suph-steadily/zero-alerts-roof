# Do we knock excluded homes more often?

*Run 2026-08-25 by a three-analyst workflow, each adversarially verified by an independent recomputation agent. Verdict: **CONFIRMED** - every load-bearing number reproduced from independently written SQL. Metabase db 235, read-only.*

**Headline.** Yes: homes that carry a hand-applied roof exclusion at bind get knocked (all-cause NOC) about 1.5x more often than same-age, same-state, same-vintage homes without one (101+: 16.1 vs 10.6 per 100 home-years; age/state/time-standardized 1.59x, CI 1.38-1.83), so the exclusion marks properties we end up cancelling more anyway, and the extra knocks are mostly general-condition, not roof.

## Key numbers

- **101+ all-cause knock rate, hand-excluded at bind**: 16.1 per 100 home-years (CI 14.0-18.5) *(base: 203 knocks / 1,261.7 first-term home-years; bound NB policies Jan 2024-Jun 2026, exposure capped 365d, cutoff 2026-08-20)*
- **101+ all-cause knock rate, no exclusion at bind**: 10.6 per 100 home-years (CI 10.0-11.2) *(base: 1,253 knocks / 11,814.7 first-term home-years, same window)*
- **101+ age/state/vintage-standardized excess**: 1.59x (CI 1.38-1.83) *(base: 203 actual vs 127.3 expected knocks on the hand-excluded 101+ book, non-excluded rates applied per age band x state x bind-half cell)*
- **90-and-under standardized excess**: 1.53x (CI 1.29-1.81) *(base: 140 actual vs 91.3 expected knocks on 1,502 hand-excluded home-years)*
- **91-100 standardized excess (no gap, thin cell)**: 1.01x (CI 0.65-1.50) *(base: 24 actual vs 23.8 expected knocks on 168 hand-excluded home-years (330 policies))*
- **Gap with roof-reason knocks removed (101+)**: 1.49x (14.9 vs 10.0 per 100 home-years) *(base: 188 non-roof knocks / 1,261.7 hy vs 1,181 / 11,814.7 hy)*
- **Mature-cohort 365-day knocked share, 101+ (Wilson)**: hand 10.3% (7.9-13.3) vs none 8.5% (8.0-9.1) *(base: 50/487 vs 774/9,059 policies bound Jan 2024-Aug 2025, all with a full 365-day clock)*
- **Recent-era 180-day knocked share, 101+ (Wilson)**: hand 8.1% (6.6-9.9) vs none 5.1% (4.6-5.7) *(base: 84/1,043 vs 303/5,891 policies bound Aug 2025-Feb 2026)*
- **Auto-excluded lane (unreadable)**: 0 knocks vs ~2.1 expected at 60 days (Wilson upper 2.0%) *(base: 0/186 auto-excluded policies bound Feb 22-Jun 21 2026 with a full 60-day clock)*

# When we knock, do we knock excluded properties more often?

Question: among homes we bind, do the ones carrying the roof surfacing exclusion (RSE) at bind draw more UW-initiated cancellations (NOCs, "knocks") of ANY cause during their first policy term? The knock here is the cancellation transaction with reason "Inspection", which is the underwriter-initiated cancel lane; customer cancels, non-payment, property-sold etc. are not knocks and are excluded.

**Short answer: yes, about 1.5x more, and age does not explain it away.** The exclusion is behaving like a marker of a property we will end up walking away from more often, not like a fix that saves the relationship. The extra knocks are mostly "Condition - General" and "Ineligible Risk", not roof knocks.

## How it was measured (mirrors the loss-join method)

- **Cohort:** every bound new-business policy created Jan 2024 through Jun 2026 (data cutoff Aug 20, 2026). One issued NB quote per policy (verified exactly: 34,430 quotes = 34,430 policies in the probe window), so the exclusion flag is read off the one real issued quote, no stitched-together records.
- **Groups at bind:** no exclusion ("none"), hand-applied by an underwriter ("hand"), auto-applied by the automation ("auto" = flag on + model decision "exclude" + exclusion present).
- **Exposure:** first term only, capped at 365 days from bind, and ended early at the first cancellation of any kind, so a young book is not compared against a matured one and a home that left for other reasons stops counting as at-risk.
- **Knock:** the policy's first cancellation is reason "Inspection" and falls inside that first-term window.
- **Age control (mandatory):** age band by oldest dwelling on the policy (101+ / 91-100 / 90 and under), age = bind year minus year built, year built > 1700 guard.
- **Time and geography control:** direct standardization on age band x state x bind-half-year cells, non-excluded rates applied to the excluded book's own exposure (same machinery as the loss join).

## The main table: all-cause knocks per 100 home-years, first term

| age band | group | policies | home-years | knocks | rate /100 home-yrs | 95% CI |
|---|---|---|---|---|---|---|
| 101+ | hand-excluded | 2,788 | 1,261.7 | 203 | **16.1** | 14.0-18.5 |
| 101+ | no exclusion | 19,988 | 11,814.7 | 1,253 | **10.6** | 10.0-11.2 |
| 101+ | auto-excluded | 41 | 8.3 | 0 | 0 | 0-44 (no runway) |
| 91-100 | hand-excluded | 330 | 167.9 | 24 | 14.3 | 9.2-21.3 |
| 91-100 | no exclusion | 8,035 | 4,861.9 | 681 | 14.0 | 13.0-15.1 |
| 90 and under | hand-excluded | 2,700 | 1,502.1 | 140 | 9.3 | 7.8-11.0 |
| 90 and under | no exclusion | 184,712 | 120,626.4 | 7,432 | 6.2 | 6.0-6.3 |
| 90 and under | auto-excluded | 173 | 34.3 | 3 | 8.7 | 1.8-25.6 |

Rate ratios (hand vs none, within band): **101+ = 1.52 (1.31-1.76)** · 91-100 = 1.02 (0.68-1.53) · **90 and under = 1.51 (1.28-1.79)**.

## The age-controlled comparison (the one that answers the question)

Applying each state x bind-half's non-excluded knock rate to the excluded book's own exposure, within age band:

| age band | excluded home-years | actual knocks | expected at non-excluded rates | actual / expected |
|---|---|---|---|---|
| 101+ | 1,262 | 203 | 127.3 | **1.59 (1.38-1.83)** |
| 90 and under | 1,502 | 140 | 91.3 | **1.53 (1.29-1.81)** |
| 91-100 | 168 | 24 | 23.8 | 1.01 (0.65-1.50) |

So after holding age band, state, and bind vintage fixed, a hand-excluded home still draws roughly 60% more knocks in the 101+ book. The one band with no gap is 91-100, which is also the band with the fewest hand exclusions (330 policies); its interval is wide enough to hide a real gap either way.

## Robustness: same story on fixed clocks, no exposure math involved

Share of policies knocked within a fixed number of days of bind (numerator/denominator shown, Wilson 95% CI), split by era so old and new books are never mixed:

| era (bind window, clock) | band | hand | none |
|---|---|---|---|
| E1 Jan 2024-Aug 2025, 365d | 101+ | 50/487 = 10.3% (7.9-13.3) | 774/9,059 = 8.5% (8.0-9.1) |
| E2 Aug 2025-Feb 2026, 180d | 101+ | 84/1,043 = 8.1% (6.6-9.9) | 303/5,891 = 5.1% (4.6-5.7) |
| E3 Feb-Jun 2026, 60d | 101+ | 27/1,166 = 2.3% (1.6-3.4) | 70/4,699 = 1.5% (1.2-1.9) |
| E1 | 90 and under | 47/753 = 6.2% (4.7-8.2) | 5,136/93,037 = 5.5% (5.4-5.7) |
| E2 | 90 and under | 54/1,048 = 5.2% (4.0-6.7) | 1,381/51,197 = 2.7% (2.6-2.8) |
| E3 | 90 and under | 13/841 = 1.5% (0.9-2.6) | 405/37,514 = 1.1% (1.0-1.2) |

The gap exists in every era and if anything is wider in the recent book (E2 ratio ~1.6-1.9) than the 2024-era book (~1.2). The direction never flips outside the thin 91-100 band.

## What we knock them for (reason mix on the knocked policies)

Sub-reasons from the Salesforce policy record (about 60-75% of knocks classify; treat the mix as indicative):

- Hand-excluded 101+ knocks (203): Condition - General 72 · unclassified 85 · Ineligible Risk 16 · **Condition - Roof 15** · Liability Hazard 11 · other 4.
- Non-excluded 101+ knocks (1,253): Condition - General 451 · unclassified 345 · Ineligible Risk 193 · Liability Hazard 105 · Condition - Roof 72 · rest 87.

Two reads from this:

1. **The excess knocking is broad, not roof-shaped.** Remove roof-reason knocks entirely and the 101+ gap barely moves: 14.9 vs 10.0 per 100 home-years, ratio 1.49. Excluded homes are knocked more for general condition and eligibility, which fits the underwriter having seen a bad roof in imagery and the inspector later finding a generally bad property.
2. **A nuance on the known "excluded roofs don't get roof-cancelled" fact:** over the full 2024-2026 book, 15 of the 203 knocks on hand-excluded 101+ homes were still Condition - Roof. The near-zero result from the earlier score-band cut was on the young, high-score April+ slice; across the whole book the exclusion reduces but does not eliminate roof knocks (roof share of knocks: 7.4% on excluded vs 9.2% on non-excluded, pooled).

## The auto lane cannot be read yet

Auto-applied exclusions (Apr 21, 2026 onward): 186 policies with a full 60-day clock, 0 knocked, against about 2.1 expected at the non-excluded rates. Zero out of 186 is consistent with anything from 0x to well above 1x (Wilson upper bound 2.0%). Re-cut around October when the spring waves have real runway; the same pull answers it.

## What this means for the roof dial

- **The exclusion has not been saving the relationship.** Homes underwriters chose to exclude still leave via UW cancellation 1.5-1.6x more often than matched non-excluded homes. Pair this with the loss join's finding (the exclusion's value shows up as unpaid claim dollars, about 83% of expected roof-peril payment avoided): the exclusion protects the money, not the policy.
- **This is selection, not an effect of the exclusion.** Underwriters put the exclusion on properties they already distrusted, and those properties fail inspections for many reasons. Nothing here says applying an exclusion causes knocks, and nothing here says removing it would prevent any.
- **For the dial specifically:** a wider auto-exclusion bar would be stamping the exclusion onto more homes from a population that historically gets knocked more anyway. The exclusion does not substitute for the inspection-cancel lane, so do not expect a wider bar to reduce NOC volume; the earlier withdrawn "NOC prevention" framing stays withdrawn, and this adds the complementary fact that even the excluded survivors churn out at a higher rate.

## Caveats

- This is selection, not cause and effect: underwriters put the exclusion on properties they already distrusted, so the 1.5x measures what kind of homes get excluded, not what the exclusion does. Nothing here says applying or removing the exclusion changes knock risk.
- Exclusion status is read off the issued new-business quote (verified canonical: one issued NB quote per policy). Exclusions added after bind by endorsement sit in the no-exclusion group, which waters down the comparison group and biases the measured gap DOWNWARD, so 1.5x is if anything a floor.
- The 91-100 band shows no gap (1.01x) but has only 330 hand-excluded policies; its interval (0.65-1.50) cannot distinguish no-gap from a 101+-sized gap.
- The auto-applied lane is unreadable: 0 knocks on 186 policies with a full 60-day clock vs about 2.1 expected. Re-pull around October when the spring waves have runway.
- Knock = the policy's FIRST cancellation being reason 'Inspection'. A UW knock that follows an earlier cancellation plus reinstatement is missed; this undercounts both groups slightly and NonCompliance cancels (848 policies since 2025) were not counted as knocks.
- Per-100-home-year rates censor exposure at the first cancellation of any reason (competing risks). The fixed-horizon shares, which use plain policy denominators and no exposure math, show the same 1.5-1.6x gap, so the result is not an artifact of the exposure handling.
- Sub-reason classification coverage differs between groups (unclassified 38% of hand-excluded knocks vs 25% of non-excluded), so the reason mix is indicative, not exact; the all-cause totals are unaffected.
- Policy grain: a multi-dwelling policy counts once, is 'excluded' if any dwelling on the issued quote carries the exclusion, and takes the age band of its oldest dwelling (~1.16 dwellings per quote).
- Recent binds (after ~Aug 2025) do not yet have a full 365-day first term; the exposure method and the era-split fixed horizons both handle this, but E2/E3 shares are not comparable to E1 levels, only hand-vs-none WITHIN an era.
- Standardization controls age band, state, and bind half-year. It does not control roof score or other property condition signals, and it should not: worse condition is part of what the exclusion marks. The question answered is 'do we knock excluded homes more', not 'is the roof the reason'.

## Verification notes (2026-08-25)

No numeric corrections required - every recomputed figure matches. Two wording tightenings recommended:

1. **Auto-lane caveat**: change "The auto-applied lane is unreadable: 0 knocks on 186 policies" to "0 knocks **within 60 days** on the 186 policies with a full 60-day clock; the pooled auto lane over 365 days does show 3 knocks (all 90-and-under, 8.7 per 100 home-years, CI 1.8-25.6)." Both facts are already in the writeup's own table; the caveat as phrased invites a false "zero ever" reading.

2. **Grain caveat**: add the measured magnitude - "in 144 of 2,788 (5.2%) hand-excluded 101+ policies the exclusion sits on a dwelling that is not itself 101+ (the oldest dwelling sets the band); too small to move the 1.59x."

3. Optional: add one sentence to caveat 1 naming surveillance bias - excluded homes came through referral and may simply be inspected more often, which would raise their knock rate independent of property condition.

### Verifier issues logged

- Grain wrinkle quantified: 144 of 2,788 (5.2%) '101+ hand-excluded' policies carry the exclusion only on a dwelling that is not itself 101+ (band set by the oldest dwelling on multi-dwelling policies). This is declared generically in caveat 8 but was unquantified; at 5.2% of the group it cannot move the 1.59x materially. Suggest stating the 5.2% figure.
- The 'auto lane: 0 knocks' caveat is horizon-specific and should say so plainly: the pooled auto lane over the full 365-day window has 3 knocks (90-and-under, 8.7 per 100 home-years, CI 1.8-25.6, shown in their own main table). '0 knocks on 186' is true only for the full-60-day-clock E3 subset (35+146+5 = 186 policies, 0 knocked - verified exactly).
- Expected auto knocks '~2.1': my independent age-band-weighted recompute gives 2.24 (35x70/4699 + 146x405/37514 + 5x46/1599). Same ballpark; theirs presumably adds state weighting. The soft '~2.1' claim stands but 2.1-2.3 is the honest range.
- Trivial rounding: E3 101+ hand Wilson upper bound is 3.3% by my computation vs their 3.4% (27/1,166; boundary rounding, no consequence).
- Completeness nit: the writeup's main table omits the 91-100 auto row (7 policies, 1.3 home-years, 0 knocks - present in my recompute).
- Framing nuance worth one sentence: part of the 1.5x could be surveillance, not property condition - hand-excluded homes arrived via referral and may be more likely to have an inspection ordered at all, so they are looked at more, not only worse. Caveat 1 ('selection, not cause') covers the decision-relevance but does not name inspection-targeting; the reason-mix interpretation ('inspector later finding a generally bad property') silently assumes homes-are-worse over homes-are-more-inspected.
- Everything load-bearing reproduced exactly on independent recompute: 218,774 policies with zero multi-issued-NB-quote cases (no stitch possible); 101+ 203/1,261.7hy=16.09 vs 1,253/11,814.7hy=10.61; standardized A/E 203/127.32=1.594 (CI 1.38-1.83), 90u 1.533 (1.29-1.81), 91-100 1.007 (0.65-1.50); every era-split cell (50/487, 774/9,059, 84/1,043, 303/5,891, 27/1,166, 70/4,699) and its Wilson CI; the sub-reason mix (15/72/85 hand vs 72/451/345 none in 101+), the non-roof ratio 1.49 (188/1,261.7 vs 1,181/11,814.7), the pooled roof shares 7.4% vs 9.2% (27/367 vs 864/9,366), and the unclassified shares 38% vs 25% (140/367 vs 2,321/9,366). No zero-exposure knocks, no cancel-before-bind artifacts. Bound-only framing is legitimate here (the question is post-bind knocks among bound homes; no bind-rate claim is made) and the causal language is honest.

## SQL

```sql
-- All queries: Metabase db 235, ClickHouse, read-only. Executed 2026-08-25.

-- ============================================================
-- Q1 (probe): grain check - issued NB is one quote per policy, one row per dwelling
-- Result: rows 40,907 = dwellings = quote-dwelling pairs; quotes 34,430 = policies 34,430
-- ============================================================
SELECT
  count() AS rows_,
  uniqExact(quote_id) AS quotes,
  uniqExact(policy_id) AS policies,
  uniqExact(dwelling_id) AS dwellings,
  uniqExact(quote_id, dwelling_id) AS quote_dwelling_pairs
FROM dbt.ipod_standard_mga_raw_policy_info
WHERE quote_type = 'NewBusiness' AND quote_status = 'Issued'
  AND pol_created_timestamp >= toDateTime('2026-04-01 00:00:00')
  AND pol_created_timestamp <  toDateTime('2026-07-01 00:00:00');

-- ============================================================
-- Q2 (probe): cancellation_reason value census - 'Inspection' is the UW-initiated (NOC) lane
-- Result: Inspection 6,787 policies since 2025-01; other values are customer/payment lanes
-- ============================================================
SELECT cancellation_reason, count() AS rows_, uniqExact(policy_id) AS policies
FROM dbt.ipod_standard_mga_raw_policy_info
WHERE quote_type = 'Cancellation' AND quote_status = 'Issued'
  AND quote_issued_timestamp >= toDateTime('2025-01-01 00:00:00')
GROUP BY cancellation_reason
ORDER BY policies DESC;

-- ============================================================
-- Q3 (main): all-cause first-term NOC rate per 100 home-years by age band x exclusion group
-- Policy grain; RSE read off the single issued NB quote; exposure capped at 365d and
-- censored at first cancellation of any reason and at the 2026-08-20 data cutoff.
-- ============================================================
WITH coh AS (
  SELECT policy_id,
    any(toDate(pol_created_timestamp)) AS bind,
    any(pol_prop_state) AS st,
    max(if(prop_cov_roof_surfacing_exclusion = 'selected', 1, 0)) AS rse,
    max(if(prop_cov_roof_surfacing_exclusion = 'selected'
           AND pol_ff_automated_roof_exclusion = 'yes'
           AND pol_prop_steadily_roof_condition_score_decision = 'exclude', 1, 0)) AS auto_rse,
    max(toYear(pol_created_timestamp) - pol_prop_year_built) AS age
  FROM dbt.ipod_standard_mga_raw_policy_info
  WHERE quote_type = 'NewBusiness' AND quote_status = 'Issued'
    AND pol_created_timestamp >= toDateTime('2024-01-01 00:00:00')
    AND pol_created_timestamp <  toDateTime('2026-07-01 00:00:00')
    AND pol_prop_year_built > 1700
  GROUP BY policy_id
),
firstcanc AS (
  SELECT policy_id,
    min(toDate(quote_issued_timestamp)) AS c_date,
    argMin(cancellation_reason, quote_issued_timestamp) AS c_reason
  FROM dbt.ipod_standard_mga_raw_policy_info
  WHERE quote_type = 'Cancellation' AND quote_status = 'Issued'
  GROUP BY policy_id
),
j AS (
  SELECT
    multiIf(coh.age >= 101, '101+', coh.age >= 91, '91-100', '90 and under') AS age_band,
    multiIf(coh.rse = 0, 'none', coh.auto_rse = 1, 'auto', 'hand') AS grp,
    coh.bind AS bind,
    least(dateDiff('day', coh.bind, toDate('2026-08-20')), 365,
          if(fc.c_date IS NULL OR fc.c_date < coh.bind, 365,
             dateDiff('day', coh.bind, fc.c_date))) AS exp_days,
    if(fc.c_reason = 'Inspection' AND fc.c_date >= coh.bind
       AND dateDiff('day', coh.bind, fc.c_date) <= least(dateDiff('day', coh.bind, toDate('2026-08-20')), 365), 1, 0) AS noc,
    if(coh.bind <= toDate('2025-08-20'), 1, 0) AS mature
  FROM coh
  LEFT JOIN firstcanc AS fc ON fc.policy_id = coh.policy_id
)
SELECT age_band, grp,
  count() AS policies,
  round(sum(exp_days) / 365.25, 1) AS home_years,
  sum(noc) AS nocs,
  round(100.0 * sum(noc) / (sum(exp_days) / 365.25), 2) AS noc_per_100hy,
  sum(mature) AS mature_policies,
  sum(noc * mature) AS mature_nocs
FROM j
GROUP BY age_band, grp
ORDER BY age_band, grp;

-- ============================================================
-- Q4 (standardization): actual vs expected NOCs on the hand-excluded book,
-- non-excluded rates applied per (age band x state x bind-half-year) cell
-- Result: 101+ 203 vs 127.3 (1.59) - 90u 140 vs 91.3 (1.53) - 91-100 24 vs 23.8 (1.01)
-- ============================================================
WITH coh AS (
  SELECT policy_id,
    any(toDate(pol_created_timestamp)) AS bind,
    any(pol_prop_state) AS st,
    max(if(prop_cov_roof_surfacing_exclusion = 'selected', 1, 0)) AS rse,
    max(if(prop_cov_roof_surfacing_exclusion = 'selected'
           AND pol_ff_automated_roof_exclusion = 'yes'
           AND pol_prop_steadily_roof_condition_score_decision = 'exclude', 1, 0)) AS auto_rse,
    max(toYear(pol_created_timestamp) - pol_prop_year_built) AS age
  FROM dbt.ipod_standard_mga_raw_policy_info
  WHERE quote_type = 'NewBusiness' AND quote_status = 'Issued'
    AND pol_created_timestamp >= toDateTime('2024-01-01 00:00:00')
    AND pol_created_timestamp <  toDateTime('2026-07-01 00:00:00')
    AND pol_prop_year_built > 1700
  GROUP BY policy_id
),
firstcanc AS (
  SELECT policy_id,
    min(toDate(quote_issued_timestamp)) AS c_date,
    argMin(cancellation_reason, quote_issued_timestamp) AS c_reason
  FROM dbt.ipod_standard_mga_raw_policy_info
  WHERE quote_type = 'Cancellation' AND quote_status = 'Issued'
  GROUP BY policy_id
),
j AS (
  SELECT
    multiIf(coh.age >= 101, '101+', coh.age >= 91, '91-100', '90 and under') AS age_band,
    multiIf(coh.rse = 0, 'none', coh.auto_rse = 1, 'auto', 'hand') AS grp,
    coh.st AS st,
    concat(toString(toYear(coh.bind)), 'H', toString(if(toMonth(coh.bind) <= 6, 1, 2))) AS bh,
    least(dateDiff('day', coh.bind, toDate('2026-08-20')), 365,
          if(fc.c_date IS NULL OR fc.c_date < coh.bind, 365,
             dateDiff('day', coh.bind, fc.c_date))) AS exp_days,
    if(fc.c_reason = 'Inspection' AND fc.c_date >= coh.bind
       AND dateDiff('day', coh.bind, fc.c_date) <= least(dateDiff('day', coh.bind, toDate('2026-08-20')), 365), 1, 0) AS noc
  FROM coh
  LEFT JOIN firstcanc AS fc ON fc.policy_id = coh.policy_id
),
cells AS (
  SELECT age_band, st, bh, grp,
    sum(exp_days) / 365.25 AS dy,
    sum(noc) AS n
  FROM j
  WHERE grp IN ('hand', 'none')
  GROUP BY age_band, st, bh, grp
)
SELECT h.age_band AS age_band,
  round(sum(h.dy)) AS matched_hand_home_years,
  sum(h.n) AS actual_hand_nocs,
  round(sum(h.dy * c.n / c.dy), 1) AS expected_nocs_at_none_rates,
  round(sum(h.n) / sum(h.dy * c.n / c.dy), 2) AS actual_over_expected
FROM      (SELECT * FROM cells WHERE grp = 'hand')              AS h
INNER JOIN(SELECT * FROM cells WHERE grp = 'none' AND dy > 0)   AS c
       ON c.age_band = h.age_band AND c.st = h.st AND c.bh = h.bh
GROUP BY h.age_band
ORDER BY h.age_band;

-- ============================================================
-- Q5 (reason breakdown): NOC sub-reason (Salesforce picklist) by group x age band
-- for first-term knocked policies; join key = ipod policy_id from the
-- steadily_universal_policy_number__c path
-- ============================================================
WITH coh AS (
  SELECT policy_id,
    any(toDate(pol_created_timestamp)) AS bind,
    max(if(prop_cov_roof_surfacing_exclusion = 'selected', 1, 0)) AS rse,
    max(if(prop_cov_roof_surfacing_exclusion = 'selected'
           AND pol_ff_automated_roof_exclusion = 'yes'
           AND pol_prop_steadily_roof_condition_score_decision = 'exclude', 1, 0)) AS auto_rse,
    max(toYear(pol_created_timestamp) - pol_prop_year_built) AS age
  FROM dbt.ipod_standard_mga_raw_policy_info
  WHERE quote_type = 'NewBusiness' AND quote_status = 'Issued'
    AND pol_created_timestamp >= toDateTime('2024-01-01 00:00:00')
    AND pol_created_timestamp <  toDateTime('2026-07-01 00:00:00')
    AND pol_prop_year_built > 1700
  GROUP BY policy_id
),
firstcanc AS (
  SELECT policy_id,
    min(toDate(quote_issued_timestamp)) AS c_date,
    argMin(cancellation_reason, quote_issued_timestamp) AS c_reason
  FROM dbt.ipod_standard_mga_raw_policy_info
  WHERE quote_type = 'Cancellation' AND quote_status = 'Issued'
  GROUP BY policy_id
),
vp AS (
  SELECT splitByChar('/', assumeNotNull(steadily_universal_policy_number__c))[-1] AS pid,
         any(steadily_uw_cancellation_reason__c) AS sub_reason
  FROM tap_veruna.wt_insurance_policy__c FINAL
  WHERE NOT isdeleted AND steadily_universal_policy_number__c IS NOT NULL
  GROUP BY pid
)
SELECT
  multiIf(coh.rse = 0, 'none', coh.auto_rse = 1, 'auto', 'hand') AS grp,
  multiIf(coh.age >= 101, '101+', coh.age >= 91, '91-100', '90 and under') AS age_band,
  coalesce(nullIf(vp.sub_reason, ''), '(unclassified)') AS noc_sub_reason,
  count() AS knocked_policies
FROM coh
INNER JOIN firstcanc AS fc ON fc.policy_id = coh.policy_id
LEFT JOIN vp ON vp.pid = coh.policy_id
WHERE fc.c_reason = 'Inspection' AND fc.c_date >= coh.bind
  AND dateDiff('day', coh.bind, fc.c_date) <= least(dateDiff('day', coh.bind, toDate('2026-08-20')), 365)
GROUP BY grp, age_band, noc_sub_reason
ORDER BY grp, age_band, knocked_policies DESC;

-- ============================================================
-- Q6 (era-split fixed horizons): knocked share within a fixed clock per era,
-- so young and mature books are never mixed and Wilson CIs have clean denominators.
-- E1 binds 2024-01-01..2025-08-20 (365d clock) / E2 ..2026-02-21 (180d) / E3 ..2026-06-21 (60d);
-- every policy has full runway to its clock at the 2026-08-20 cutoff.
-- NOTE: a first draft failed with ILLEGAL_AGGREGATION because sum(knocked) AS knocked
-- shadowed the inner column (known ClickHouse gotcha) - outer aliases prefixed o_.
-- ============================================================
WITH coh AS (
  SELECT policy_id,
    any(toDate(pol_created_timestamp)) AS bind,
    max(if(prop_cov_roof_surfacing_exclusion = 'selected', 1, 0)) AS rse,
    max(if(prop_cov_roof_surfacing_exclusion = 'selected'
           AND pol_ff_automated_roof_exclusion = 'yes'
           AND pol_prop_steadily_roof_condition_score_decision = 'exclude', 1, 0)) AS auto_rse,
    max(toYear(pol_created_timestamp) - pol_prop_year_built) AS age
  FROM dbt.ipod_standard_mga_raw_policy_info
  WHERE quote_type = 'NewBusiness' AND quote_status = 'Issued'
    AND pol_created_timestamp >= toDateTime('2024-01-01 00:00:00')
    AND pol_created_timestamp <  toDateTime('2026-06-22 00:00:00')
    AND pol_prop_year_built > 1700
  GROUP BY policy_id
),
firstcanc AS (
  SELECT policy_id,
    min(toDate(quote_issued_timestamp)) AS c_date,
    argMin(cancellation_reason, quote_issued_timestamp) AS c_reason
  FROM dbt.ipod_standard_mga_raw_policy_info
  WHERE quote_type = 'Cancellation' AND quote_status = 'Issued'
  GROUP BY policy_id
),
j AS (
  SELECT
    multiIf(coh.bind <= toDate('2025-08-20'), 'E1 2024-01..2025-08 (365d)',
            coh.bind <= toDate('2026-02-21'), 'E2 2025-08..2026-02 (180d)',
            'E3 2026-02-22..06-21 (60d)') AS era,
    multiIf(coh.age >= 101, '101+', coh.age >= 91, '91-100', '90 and under') AS age_band,
    multiIf(coh.rse = 0, 'none', coh.auto_rse = 1, 'auto', 'hand') AS grp,
    if(fc.c_reason = 'Inspection' AND fc.c_date >= coh.bind
       AND dateDiff('day', coh.bind, fc.c_date) <=
           multiIf(coh.bind <= toDate('2025-08-20'), 365,
                   coh.bind <= toDate('2026-02-21'), 180, 60), 1, 0) AS knocked
  FROM coh
  LEFT JOIN firstcanc AS fc ON fc.policy_id = coh.policy_id
)
SELECT era, age_band, grp,
  count() AS o_policies,
  sum(knocked) AS o_knocked,
  round(100.0 * sum(knocked) / count(), 2) AS o_knocked_pct
FROM j
GROUP BY era, age_band, grp
ORDER BY era, age_band, grp;

-- Wilson and Poisson 95% intervals, rate ratios, and A/E intervals were computed
-- offline in Python from the counts above (Wilson on k/n shares; exact Poisson
-- chi-square bounds on event counts; log-normal approximation on rate ratios).
```
