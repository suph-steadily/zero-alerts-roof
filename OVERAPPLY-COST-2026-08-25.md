# The real cost of over-applying the roof exclusion

*Run 2026-08-25 by a three-analyst workflow, each adversarially verified by an independent recomputation agent. Verdict: **CONFIRMED** - every load-bearing number reproduced from independently written SQL. Metabase db 235, read-only.*

**Headline.** Over-applying the roof exclusion by machine has, so far, cost almost nothing we can measure: the live auto-exclusion lane binds at the same rate as the old hand lane (11.3% vs 10.8%), only 9 of 436 auto-applied exclusions have been pushed back off after bind (~2%, about twice the hand rate), and the real growing cost is a compliance lane of ~65-70 bound policies a month carrying an exclusion no underwriter ever saw - while the benefit of each extra marginal exclusion still cannot be measured (24 of the 25 excluded-book claims predate the roof score).

## Key numbers

- **Bind rate, auto-applied exclusion vs old hand lane**: 11.30% vs 10.75% (no difference, p=0.47; +2.4pp after state-mix placebo) *(base: 386/3,415 vs 376/3,499 quotes where the model said exclude; all NB quotes created Apr 1-Jul 31 2026, bound or not)*
- **Worst-case bind drag (score-matched within flag-on states)**: -1.4pp (10.97% vs 12.34%, p=0.07); shrinks to -0.3pp at scores 95+ *(base: 294/2,680 auto-excluded vs 721/5,845 same-score (85+) not excluded, creations Apr 15-Jul 31)*
- **Post-bind removals of auto-applied exclusions (was n=1)**: 9 of 436 = 2.06% [1.09-3.88]; all stayed off; median 30 days to removal *(base: auto-applied bind-time exclusions on Apr 1+ binds, removal = later issued endorsement without the exclusion, as of Aug 25)*
- **Auto vs hand pushback, runway-fair**: 2.36% vs 0.93% (~2.5x, Fisher p=0.051) *(base: 6/254 vs 18/1,931; binds through Jul 10, removal within 45 days)*
- **Never-seen compliance lane, current actual**: ~65-70 bound policies/mo (69 in Jul = 66% of all auto-exclusion binds) *(base: bound quotes with auto-applied exclusion, no substantive gating alert AND no referral note; strict-count by bind month)*
- **Marginal-benefit split feasibility**: INFEASIBLE: 24 of 25 excluded-book wind/hail claims are on pre-score-era binds (1 scored, paid $399) *(base: 25 first-term wind/hail claims on the 2024-01 to 2026-06 excluded bound book)*

# What over-applying the roof exclusion actually costs: the ledger as of Aug 25

**The question.** If we move from underwriters hand-picking which old roofs get the roof surfacing exclusion (the policy clause that stops us paying to replace a worn roof surface after wind or hail) to an automatic score-bar rule, many homes get the exclusion an underwriter would have left alone. What does that cost? The old "72-75% false positives" table stays withdrawn - nothing here rebuilds it. Instead this measures the cost terms that are measurable today, mostly by using the automation we already run (score-triggered, no human judgment, live since Apr 21) as the closest real-world stand-in for over-application.

## 1. Bind rate: the live experiment says the exclusion does not scare quotes away

Population: every new-business quote created Apr 1 - Jul 31, 2026, bound or not (this fixes the survivor-bias defect from the earlier curve). "Model said exclude" quotes split by whether the automation flag was on (exclusion applied instantly, no underwriter) or off (the old lane: referral, sometimes a hand-applied exclusion - 521 of the 3,499 flag-off quotes got one).

| group | quotes | bound | bind rate (Wilson 95%) |
|---|---|---|---|
| model said exclude, **auto-applied** (flag on) | 3,415 | 386 | **11.30%** (10.28-12.41) |
| model said exclude, **not auto-applied** (flag off) | 3,499 | 376 | **10.75%** (9.76-11.82) |
| clean "pass" quotes, flag-on states | 97,804 | 15,481 | 15.83% |
| clean "pass" quotes, flag-off states | 160,199 | 28,261 | 17.64% |

- The two exclude lanes are statistically identical (Fisher p = 0.47).
- The flag-on states bind ~1.8pp LOWER on clean quotes (that's just which states they are), so after netting that out, the auto-applied lane actually looks **+2.4pp better** than expected. Stable month by month (May +0.4, Jun +2.4, Jul +2.2).
- Plain reading: slapping the exclusion on instantly costs no binds versus the old lane - plausibly because the old lane's referral locks the quote, which is its own bind killer.
- Second view, worst case: within flag-on states, comparing auto-excluded quotes to quotes with the SAME roof score (85+) the model chose not to exclude: 10.97% vs 12.34% bind (-1.4pp, p = 0.07), and the gap shrinks to -0.3pp at scores 95+. Those "left alone at the same score" quotes were spared for reasons we can't see (imagery confidence), so this is a bound, not a clean match.

**So the bind cost per over-applied exclusion sits between roughly zero (vs the referral counterfactual) and about 1.4pp of bind rate (~11% relative) at the very worst.** Nothing resembling the referral lock's damage.

## 2. Post-bind pushback: n=1 is now n=9; about 2%, roughly twice the hand rate, 98% stick

Re-pulled fresh from the live table (not the frozen 8/16 snapshot): an exclusion counts as "removed" when the same dwelling's policy later issues an endorsement without it.

| applied at bind by | excluded dwellings (Apr 1+ binds) | removed later | rate (Wilson 95%) |
|---|---|---|---|
| automation | 436 | **9** | 2.06% (1.09-3.88) |
| underwriter (hand) | 2,774 | 29 | 1.05% (0.73-1.50) |

- Runway-fair version (binds through Jul 10 only, removal within a fixed 45 days): auto 6/254 = 2.36% vs hand 18/1,931 = 0.93%. Fisher p = 0.051 - auto exclusions get pushed back **about 2-2.5x more often**, right at the edge of significance.
- The 9: median 30 days from bind to removal (range 3-93); every one stayed off afterward; states NJ/CA/TN/PA/AZ; scores 84-99 at bind; **home ages 31 to 137** - the automation fires on score at any age, not just old homes.
- What this can't see: who removed them (needs the audit-log join), removals done through anything other than an issued endorsement, and the Jul/Aug binds whose runway is mostly still ahead. Treat 2% as an early floor with a wide band, not a settled rate.

## 3. The never-seen compliance lane is already ~65-70 bound policies a month - bigger than the prior estimate, because it was measuring a different thing

Bound quotes carrying an auto-applied exclusion where no substantive alert ever required an underwriter to look AND no referral note of any kind exists on the quote:

| bind month | auto-exclusion binds | of which never seen by UW (strict) |
|---|---|---|
| Apr | 7 | 3 |
| May | 83 | 48 |
| Jun | 131 | 66 |
| Jul | 105 | **69** (65.7% of the lane, CI 56-74%) |
| Aug 1-25 | 67 | 54 (≈67/mo pace) |

- **About two-thirds of every auto-exclusion bind is a policy no underwriter ever saw**, and post-expansion the lane runs ~65-70/mo.
- The prior "~34/mo" was the *additional* never-seen volume a hypothetical bar-80 rule on 101+ homes would create. Today's actual baseline (all ages, current tight setting) is already ~2x that. A wider bar stacks on top of this number - this is the disclosure/filings watch-item, and it grows mechanically with every notch of the dial.

## 4. Benefit on marginal roofs: cannot be measured yet - and here is exactly why

The loss join found ~$52 of avoided paid loss per excluded home-year on hand-picked roofs and forbade multiplying it by a wider-bar catch count. Feasibility check on splitting the excluded book's 25 wind/hail claims by roof score band: **24 of the 25 sit on binds from before April 2026, when the score didn't exist. Exactly 1 claim has a bind-time score** (80-89 band, paid $399). No split is possible; not forced. The scored excluded book only started binding in April 2026 and its claims haven't arrived yet - this becomes measurable roughly next spring.

## 5. The ledger: what one over-applied exclusion costs / saves

**Measured today (per the live automation, the closest thing to over-application in production):**
- Bind loss: **none detectable** vs the hand lane; worst-case bound -1.4pp absolute from the score-matched view.
- Pushback: **~2% get removed post-bind** (~2-2.5x the hand rate, p=0.051); ~98% stick; at current volume that is ~2 removals a month.
- Compliance exposure: **~65-70 never-reviewed exclusion binds/mo already**; every widening adds to it (prior sizing: ~+34/mo more at bar 80 on 101+).

**Bounded, not measured:**
- The saving per marginal exclusion is **at most $52/home-year** (that figure comes from the worst roofs underwriters chose by eye); the marginal roof at bar 80-85 almost certainly saves less, possibly much less. Unmeasurable until the scored excluded book accumulates claims.

**Still unknown:**
- Whether removals climb as the young auto book matures; complaints and agent abandonment before quote completion; override requests (not in these tables); the marginal avoided loss; and the exchange rate itself - how many unwanted exclusions one caught bad roof is worth. That last one is underwriting's call, and nothing here makes it.

**One-line version for the bar decision:** the measurable costs of machine-applied exclusions are small and mostly compliance-shaped, not bind-shaped or pushback-shaped - but the benefit side of a wider bar is still a blank, so the case for widening rests on an unmeasured number, not on a scary cost.

## Caveats

- The flag-on vs flag-off bind comparison is cross-state, not randomized: launch states differ from non-launch states. The pass-decision placebo nets out the state-level bind gap (and points the same direction), but residual confounding is possible.
- The 'auto-applied' label is inferred from flag='yes' AND decision='exclude' AND exclusion selected, all read off the same canonical issued row - attribution is not event-sourced (open item 6 in RESULTS-2026-08-20.md still stands).
- Pushback n is small (9 auto removals; runway-fair Fisher p=0.051 - borderline). Jul/Aug binds have incomplete runway, removals via anything other than an issued endorsement row are invisible, and the remover (agent vs customer vs UW) is not attributed here.
- 'Never seen by an underwriter' = no substantive alert with requires_uw_review AND no referral note since Mar 15. requires_uw_review means 'an alert required a look', not 'an underwriter reviewed this roof' (known defect 4), so the strict count is the defensible one and it is what is quoted.
- The score-matched comparison group (same score, model chose not to exclude) is selected by the model's non-score inputs (imagery confidence), so its -1.4pp is a worst-case bound, not a causal estimate.
- Bind rates are bound-as-of-Aug-25 for creations through Jul 31; the July cohort is mildly right-censored (affects both arms of each within-month comparison equally).
- The quote-grain max() aggregates across dwellings within one quote (any-dwelling flags); this is not the withdrawn independent-max() version stitch - statuses are ~unique per quote (0.4% overlap, verified in Q2).
- Term 4 stays open by design: only 1 of 25 excluded-book wind/hail claims has a bind-time roof score, so avoided-loss-by-marginality cannot be measured until the scored (Apr 2026+) excluded book accumulates claim runway, roughly spring 2027.
- No exchange rate is proposed anywhere in this analysis - valuing one caught bad roof against one unwanted exclusion remains underwriting's decision.
- All work was read-only SELECT queries against Metabase db 235; nothing was written, committed, or published.

## Verification notes (2026-08-25)

No numeric corrections. Two caveat-level fixes for the memo text: (1) replace the stitch defense "statuses are ~unique per quote (0.4% overlap, verified in Q2)" with the direct check - 3,414 of 3,415 auto-labeled quotes have flag='yes' AND decision='exclude' on the same row (1 cross-row stitch, bound with RSE; 11.30% -> 11.28% if reclassified, immaterial), and the pushback census has zero multi-issued-row or inconsistently-classified (policy,dwelling) keys; (2) relabel the pooled placebo rows from "flag-on states" to "flag-on quotes" (pre-wave launch-state quotes sit in the flag-off bucket), leaning on the monthly DiD cuts which are clean and point the same direction.

### Verifier issues logged

- Footnote nit 1: the caveat defending against the independent-max() stitch cites the wrong probe. Q2 verified quote_status overlap (0.4%), which says nothing about flag x decision being read off the same row. My direct probe closes the gap: of 3,415 quotes labeled auto (max(flag='yes') AND max(decision='exclude') independently), 3,414 have a single row carrying BOTH conditions; exactly 1 quote is a cross-row stitch (it bound, with RSE, so moving it changes 11.30% to 11.28% - immaterial). In the pushback census, zero (policy,dwelling) keys have multiple issued NB rows and zero have inconsistent auto/hand classification across rows, so LIMIT 1 BY was safe. Conclusion unchanged, but the memo should cite this check, not Q2.
- Footnote nit 2: the pooled table rows labeled 'clean pass quotes, flag-on states' are actually flag-on QUOTES. Launch-state quotes created before their wave date (e.g., Apr 1-20 in AZ/NJ) carry flag='no'/'' and land in the flag-off bucket, so the pooled placebo mixes state with rollout timing. The monthly DiD cuts (May/Jun/Jul, all post-launch) largely fix this and point the same way (+0.4/+2.4/+2.2pp), and the cross-state confounding caveat already covers the substance - relabel to 'flag-on quotes' or drop the April rows from the pooled placebo.
- Minor: 'binds' throughout are anchored on pol_created_timestamp (creation month), with bind_ts = quote_issued_timestamp only used for endorsement ordering - a Jul-created/Aug-issued policy counts as a Jul 'bind'. Consistent with SCOPE.md's own convention and immaterial at these volumes, but say 'created' where the tables say 'bind month'.
- Noted, already caveated adequately: the raw 9/436 vs 29/2,774 pushback comparison alone is not significant (my Fisher p=0.09); the 'about twice the hand rate' claim properly leans on the runway-fair cut (6/254 vs 18/1,931, Fisher p=0.051, verified), which the analysis flags as borderline.
- Everything load-bearing reproduced exactly: bind rates 376/3,499=10.75% and 386/3,415=11.30%; pushback 9/436 and 29/2,774; compliance lane Apr 3 / May 48 / Jun 66 / Jul 69 / Aug 54 never-seen-strict on 7/83/131/105/67 auto-exclusion binds; claims split 24 unscored ($40,753) vs 1 scored ($399); claims_smga correctly deduped (86,317 rows = 7,278 claims). All statistics verified: Fisher p=0.466 (quoted 0.47), Wilson CIs 10.28-12.41 / 9.76-11.82 / 1.09-3.88 / 0.73-1.50 / 56.2-74.1 all match, score-matched gap -1.37pp p=0.066-0.072 (quoted -1.4pp p=0.07), runway-fair Fisher p=0.051, pooled DiD +2.36pp (quoted +2.4), hand pushback 1.05%. None of the five withdrawn 8/21 claims are resurrected; whole-book and 101+ figures are kept apart; survivor bias avoided; causal language properly hedged.

## SQL

```sql
-- All queries: Metabase db 235 (ClickHouse), read-only, run 2026-08-25.

-- Q1: grain probe - rows vs unique quote x dwelling per status (Apr 1+ NB)
SELECT quote_status,
       count() AS rows_,
       uniqExact(quote_id) AS quotes,
       uniqExact(concat(quote_id, coalesce(dwelling_id,''))) AS quote_dwellings
FROM dbt.ipod_standard_mga_raw_policy_info
WHERE quote_type = 'NewBusiness'
  AND pol_created_timestamp >= toDateTime('2026-04-01 00:00:00')
GROUP BY quote_status;
-- Result: rows == quote_dwellings in every status (Issued 60,994 / Draft 327,724 / Quoted 3,132 / Invalidated 2,104).

-- Q2: status-overlap probe - can one quote appear under two statuses?
SELECT uniqExact(quote_id) AS total_uniq_quotes,
       count() AS total_rows,
       uniqExactIf(quote_id, quote_status='Issued') + uniqExactIf(quote_id, quote_status='Draft')
         + uniqExactIf(quote_id, quote_status='Quoted') + uniqExactIf(quote_id, quote_status='Invalidated') AS sum_by_status
FROM dbt.ipod_standard_mga_raw_policy_info
WHERE quote_type = 'NewBusiness'
  AND pol_created_timestamp >= toDateTime('2026-04-01 00:00:00');
-- Result: 339,273 unique vs 340,504 summed - only ~0.4% overlap, so quote-level max() is not a version stitch.

-- Q3: TERM 1 pooled - bind rate by model decision x automation flag, quote grain, non-bound included
WITH q AS (
  SELECT quote_id,
         max(quote_status = 'Issued') AS bound,
         max(pol_ff_automated_roof_exclusion = 'yes') AS flag_yes,
         multiIf(max(pol_prop_steadily_roof_condition_score_decision = 'exclude') = 1, 'exclude',
                 max(pol_prop_steadily_roof_condition_score_decision = 'alert') = 1, 'alert',
                 max(pol_prop_steadily_roof_condition_score_decision = 'pass') = 1, 'pass',
                 'unscored') AS decision_grp,
         max(prop_cov_roof_surfacing_exclusion = 'selected') AS rse
  FROM dbt.ipod_standard_mga_raw_policy_info
  WHERE quote_type = 'NewBusiness'
    AND pol_created_timestamp >= toDateTime('2026-04-01 00:00:00')
    AND pol_created_timestamp <  toDateTime('2026-08-01 00:00:00')
  GROUP BY quote_id
)
SELECT decision_grp, flag_yes,
       count() AS quotes,
       sum(bound) AS bound_quotes,
       sum(rse) AS rse_quotes,
       round(100.0*sum(bound)/count(),2) AS bind_pct
FROM q
GROUP BY decision_grp, flag_yes
ORDER BY decision_grp, flag_yes;
-- Result: exclude flag1 386/3,415=11.30% (3,244 with RSE) | exclude flag0 376/3,499=10.75% (521 hand RSE)
--         pass flag1 15.83% | pass flag0 17.64% | alert flag1 7.00% | alert flag0 10.32%.

-- Q4: TERM 1 by month - stability of the exclude gap vs the pass placebo
WITH q AS (
  SELECT quote_id,
         toStartOfMonth(min(pol_created_timestamp)) AS mo,
         any(pol_prop_state) AS st,
         max(quote_status = 'Issued') AS bound,
         max(pol_ff_automated_roof_exclusion = 'yes') AS flag_yes,
         multiIf(max(pol_prop_steadily_roof_condition_score_decision = 'exclude') = 1, 'exclude',
                 max(pol_prop_steadily_roof_condition_score_decision = 'alert') = 1, 'alert',
                 max(pol_prop_steadily_roof_condition_score_decision = 'pass') = 1, 'pass',
                 'unscored') AS decision_grp
  FROM dbt.ipod_standard_mga_raw_policy_info
  WHERE quote_type = 'NewBusiness'
    AND pol_created_timestamp >= toDateTime('2026-04-01 00:00:00')
    AND pol_created_timestamp <  toDateTime('2026-08-01 00:00:00')
  GROUP BY quote_id
)
SELECT mo, flag_yes,
       countIf(decision_grp='exclude') AS excl_quotes,
       sumIf(bound, decision_grp='exclude') AS excl_bound,
       round(100.0*sumIf(bound, decision_grp='exclude')/nullIf(countIf(decision_grp='exclude'),0),2) AS excl_bind_pct,
       countIf(decision_grp='pass') AS pass_quotes,
       round(100.0*sumIf(bound, decision_grp='pass')/nullIf(countIf(decision_grp='pass'),0),2) AS pass_bind_pct
FROM q
GROUP BY mo, flag_yes
ORDER BY mo, flag_yes;
-- Result (excl flag0 vs flag1 / pass flag0 vs flag1): May 10.87 vs 10.62 / 17.92 vs 17.23;
--   Jun 13.22 vs 12.53 / 18.93 vs 15.86; Jul 11.32 vs 10.20 / 17.79 vs 14.44. DiD +0.4/+2.4/+2.2pp.

-- Q5: TERM 2 - pushback census: bind-time exclusions later removed via issued endorsement, auto vs hand
WITH nb AS (
  -- canonical issued NB row per (policy, dwelling): flag, decision, exclusion read off the SAME row (no independent-max stitch)
  SELECT policy_id, dwelling_id, quote_issued_timestamp AS bind_ts,
         if(pol_ff_automated_roof_exclusion = 'yes'
            AND pol_prop_steadily_roof_condition_score_decision = 'exclude', 'auto', 'hand') AS applied_by,
         toStartOfMonth(pol_created_timestamp) AS bind_mo
  FROM dbt.ipod_standard_mga_raw_policy_info
  WHERE quote_type = 'NewBusiness' AND quote_status = 'Issued'
    AND pol_created_timestamp >= toDateTime('2026-04-01 00:00:00')
    AND prop_cov_roof_surfacing_exclusion = 'selected'
  LIMIT 1 BY policy_id, dwelling_id
),
endo AS (
  SELECT policy_id, dwelling_id, quote_issued_timestamp AS ts,
         prop_cov_roof_surfacing_exclusion AS rse
  FROM dbt.ipod_standard_mga_raw_policy_info
  WHERE quote_type = 'Endorsement' AND quote_status = 'Issued'
    AND quote_issued_timestamp >= toDateTime('2026-04-01 00:00:00')
)
SELECT nb.applied_by,
       uniqExact(nb.policy_id, nb.dwelling_id) AS excluded_dwellings,
       uniqExactIf((nb.policy_id, nb.dwelling_id), e.rse != 'selected' AND e.ts > nb.bind_ts) AS removed_later,
       uniqExactIf((nb.policy_id, nb.dwelling_id), e.ts > nb.bind_ts) AS had_any_endorsement
FROM nb
LEFT JOIN endo AS e ON e.policy_id = nb.policy_id AND e.dwelling_id = nb.dwelling_id
GROUP BY nb.applied_by;
-- Result: auto 436 excluded / 9 removed / 137 with any endo; hand 2,774 / 29 / 994.

-- Q6: TERM 2 detail - the 9 auto removals (timing, state, score, age, final state)
WITH nb AS (
  SELECT policy_id, dwelling_id, quote_issued_timestamp AS bind_ts,
         toStartOfMonth(pol_created_timestamp) AS bind_mo,
         pol_prop_state AS st,
         pol_prop_steadily_roof_condition_score_condition_score AS score,
         2026 - pol_prop_year_built AS age
  FROM dbt.ipod_standard_mga_raw_policy_info
  WHERE quote_type = 'NewBusiness' AND quote_status = 'Issued'
    AND pol_created_timestamp >= toDateTime('2026-04-01 00:00:00')
    AND prop_cov_roof_surfacing_exclusion = 'selected'
    AND pol_ff_automated_roof_exclusion = 'yes'
    AND pol_prop_steadily_roof_condition_score_decision = 'exclude'
  LIMIT 1 BY policy_id, dwelling_id
),
endo AS (
  SELECT policy_id, dwelling_id, quote_issued_timestamp AS ts,
         prop_cov_roof_surfacing_exclusion AS rse
  FROM dbt.ipod_standard_mga_raw_policy_info
  WHERE quote_type = 'Endorsement' AND quote_status = 'Issued'
    AND quote_issued_timestamp >= toDateTime('2026-04-01 00:00:00')
)
SELECT nb.bind_mo, nb.st, nb.score, nb.age,
       min(if(e.rse != 'selected' AND e.ts > nb.bind_ts, dateDiff('day', nb.bind_ts, e.ts), NULL)) AS days_to_removal,
       argMax(e.rse, e.ts) AS latest_endo_rse_state
FROM nb
INNER JOIN endo AS e ON e.policy_id = nb.policy_id AND e.dwelling_id = nb.dwelling_id
GROUP BY nb.policy_id, nb.dwelling_id, nb.bind_mo, nb.st, nb.score, nb.age
HAVING days_to_removal IS NOT NULL
ORDER BY nb.bind_mo;
-- Result: 9 rows; days 3/4/10/18/30/42/43/47/93 (median 30); scores 84-99; ages 31-137; all latest states '' (stayed off).

-- Q7: TERM 2 runway-fair - fixed 45-day removal window, binds with >=45d runway, by month
WITH nb AS (
  SELECT policy_id, dwelling_id, quote_issued_timestamp AS bind_ts,
         toStartOfMonth(pol_created_timestamp) AS bind_mo,
         if(pol_ff_automated_roof_exclusion = 'yes'
            AND pol_prop_steadily_roof_condition_score_decision = 'exclude', 'auto', 'hand') AS applied_by
  FROM dbt.ipod_standard_mga_raw_policy_info
  WHERE quote_type = 'NewBusiness' AND quote_status = 'Issued'
    AND pol_created_timestamp >= toDateTime('2026-04-01 00:00:00')
    AND prop_cov_roof_surfacing_exclusion = 'selected'
  LIMIT 1 BY policy_id, dwelling_id
),
endo AS (
  SELECT policy_id, dwelling_id, quote_issued_timestamp AS ts,
         prop_cov_roof_surfacing_exclusion AS rse
  FROM dbt.ipod_standard_mga_raw_policy_info
  WHERE quote_type = 'Endorsement' AND quote_status = 'Issued'
    AND quote_issued_timestamp >= toDateTime('2026-04-01 00:00:00')
)
SELECT nb.applied_by, nb.bind_mo,
       uniqExact(nb.policy_id, nb.dwelling_id) AS excluded_dwellings,
       uniqExactIf((nb.policy_id, nb.dwelling_id),
                   nb.bind_ts < toDateTime('2026-07-11 00:00:00')) AS with_45d_runway,
       uniqExactIf((nb.policy_id, nb.dwelling_id),
                   nb.bind_ts < toDateTime('2026-07-11 00:00:00')
                   AND e.rse != 'selected' AND e.ts > nb.bind_ts
                   AND dateDiff('day', nb.bind_ts, e.ts) <= 45) AS removed_45d
FROM nb
LEFT JOIN endo AS e ON e.policy_id = nb.policy_id AND e.dwelling_id = nb.dwelling_id
GROUP BY nb.applied_by, nb.bind_mo
ORDER BY nb.applied_by, nb.bind_mo;
-- Result: auto 254 with runway / 6 removed in 45d (2.36%); hand 1,931 / 18 (0.93%).
--   Monthly auto bound volume: Apr 7 / May 95 / Jun 147 / Jul 114 / Aug(1-25) 73.

-- Q8: TERM 3 - never-seen compliance lane on actual auto-exclusion binds, by month
WITH auto_bound AS (
  SELECT DISTINCT quote_id, toStartOfMonth(pol_created_timestamp) AS mo
  FROM dbt.ipod_standard_mga_raw_policy_info
  WHERE quote_type = 'NewBusiness' AND quote_status = 'Issued'
    AND pol_created_timestamp >= toDateTime('2026-04-01 00:00:00')
    AND pol_ff_automated_roof_exclusion = 'yes'
    AND pol_prop_steadily_roof_condition_score_decision = 'exclude'
    AND prop_cov_roof_surfacing_exclusion = 'selected'
),
gate AS (
  SELECT quote_id, max(toUInt8(requires_uw_review)) AS uw_gate
  FROM dbt_upc.uw_alerts_per_quote
  WHERE alert_category NOT IN ('DATA_SAFEGUARD','VALIDATION','SHOWSTOPPER','SYSTEM_ERROR')
    AND quote_id IN (SELECT quote_id FROM auto_bound)
  GROUP BY quote_id
),
refs AS (
  SELECT DISTINCT JSONExtractString(data, 'quote_id') AS quote_id
  FROM raw_pg_eventstore.eventstore_good_events
  WHERE name = 'underwriting_review_note'
    AND created_at >= toDateTime('2026-03-15 00:00:00')
)
SELECT ab.mo,
       count() AS auto_excl_bound_quotes,
       countIf(coalesce(g.uw_gate, 0) = 0) AS no_substantive_alert_gate,
       countIf(ab.quote_id NOT IN (SELECT quote_id FROM refs)) AS no_referral_note,
       countIf(coalesce(g.uw_gate, 0) = 0
               AND ab.quote_id NOT IN (SELECT quote_id FROM refs)) AS never_seen_strict
FROM auto_bound AS ab
LEFT JOIN gate AS g ON g.quote_id = ab.quote_id
GROUP BY ab.mo
ORDER BY ab.mo;
-- Result (total / never_seen_strict): Apr 7/3, May 83/48, Jun 131/66, Jul 105/69, Aug1-25 67/54.

-- Q9: TERM 4 feasibility - excluded-book wind/hail claims split by bind-time roof score band
WITH lc AS (
  SELECT claim_id, dwelling_id, standardized_loss_type AS lt, loss_date, total_paid
  FROM dbt.claims_smga
  WHERE dwelling_id IS NOT NULL AND dwelling_id != ''
  ORDER BY toDate(concat(splitByChar('-', claims_file)[2], '-',
                         leftPad(splitByChar('-', claims_file)[1], 2, '0'), '-01')) DESC
  LIMIT 1 BY claim_id
),
coh AS (
  SELECT dwelling_id, toDate(pol_created_timestamp) AS bind,
         pol_prop_steadily_roof_condition_score_condition_score AS score,
         least(dateDiff('day', toDate(pol_created_timestamp), toDate('2026-07-31')), 365) AS exp_days
  FROM dbt.ipod_standard_mga_raw_policy_info
  WHERE quote_type = 'NewBusiness' AND quote_status = 'Issued'
    AND pol_created_timestamp >= toDateTime('2024-01-01 00:00:00')
    AND pol_created_timestamp <  toDateTime('2026-07-01 00:00:00')
    AND pol_prop_year_built > 1700
    AND prop_cov_roof_surfacing_exclusion = 'selected'
)
SELECT multiIf(c.score IS NULL, 'unscored (pre-score-era bind)',
               c.score >= 90, 'scored 90+',
               c.score >= 80, 'scored 80-89',
               'scored below 80') AS band,
       count() AS wind_hail_claims,
       round(sum(l.total_paid)) AS total_paid,
       round(quantileExact(0.5)(l.total_paid)) AS median_paid
FROM coh AS c
INNER JOIN lc AS l ON l.dwelling_id = c.dwelling_id
WHERE l.lt IN ('Hail','Wind')
  AND l.loss_date >= c.bind AND l.loss_date <= c.bind + c.exp_days
GROUP BY band
ORDER BY band;
-- Result: unscored 24 claims ($40,753, median $481); scored 80-89: 1 claim ($399). Split infeasible.

-- Q10: TERM 1 second view - score-matched bind rate within flag-on states
WITH q AS (
  SELECT quote_id,
         max(quote_status = 'Issued') AS bound,
         max(pol_ff_automated_roof_exclusion = 'yes') AS flag_yes,
         max(pol_prop_steadily_roof_condition_score_condition_score) AS max_score,
         max(pol_prop_steadily_roof_condition_score_decision = 'exclude') AS has_exclude,
         max(prop_cov_roof_surfacing_exclusion = 'selected') AS rse
  FROM dbt.ipod_standard_mga_raw_policy_info
  WHERE quote_type = 'NewBusiness'
    AND pol_created_timestamp >= toDateTime('2026-04-15 00:00:00')
    AND pol_created_timestamp <  toDateTime('2026-08-01 00:00:00')
  GROUP BY quote_id
)
SELECT multiIf(max_score >= 95, '95+', max_score >= 90, '90-94', '85-89') AS score_band,
       has_exclude,
       count() AS quotes,
       sum(bound) AS bound_quotes,
       round(100.0*sum(bound)/count(),2) AS bind_pct,
       sum(rse) AS rse_quotes
FROM q
WHERE flag_yes = 1 AND max_score >= 85
GROUP BY score_band, has_exclude
ORDER BY score_band, has_exclude;
-- Result (not-excluded vs auto-excluded bind%): 85-89: 13.35 vs 10.59 | 90-94: 12.69 vs 11.43 | 95+: 10.84 vs 10.55.
--   Pooled 85+: 721/5,845 = 12.34% vs 294/2,680 = 10.97%.

-- Statistics (Wilson 95% CIs, two-sided Fisher exact tests, and the DiD) computed offline in Python
-- from the exact counts above; no additional warehouse queries.
```
