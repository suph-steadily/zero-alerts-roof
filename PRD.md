# PRD: Widen the roof dial, with an escape hatch

> **Codex review 2026-09-23:** CORRECTED. The recommendation is a limited test of 85 and 83 before a broader rollout. We have not established the best setting, the effect on sales, or the effect of the roof-replacement answer. Start with the [current takeaways in README](README.md#takeaways-from-the-first-read). See REVIEW-2026-09-23.md #P25.

*Draft v1, 2026-08-25. Owner: Suph. Engineering partner: Will Henry (free ~Sep 1).
Workstream 1 of the Zero Alerts project (see "Do What the Underwriter Does").
Status: DRAFT. Three supporting analyses in flight, marked [IN FLIGHT] below.*

> **Codex review 2026-09-23:** CORRECTED. This is a first read; the three supporting memos exist, but their verification banners do not resolve the open data and interpretation defects. See REVIEW-2026-09-23.md #P30.


## One story first

An agent quotes a 1912 rental in Allentown. The roof model scores it 84: tired but not
terrible. Today, nothing happens at quote time. The dwelling age alert fires, the quote
goes to underwriting, and an underwriter looks at the same imagery the model scored,
applies the roof surfacing exclusion by hand, and sends it back. The agent has waited a
day, maybe two. Most agents in this spot never come back: the dwelling age alert is our
single biggest bind killer on old homes.

> **Codex review 2026-09-23:** WITHDRAWN. The live Apr 1-Aug 11 cohort of 101+ referred quotes has a 6.8-minute median first review/immediate-decision wait among 16,777 decided quotes through Aug 25; final resolution and outside shopping remain unmeasured. See REVIEW-2026-09-23.md #P31.


In the proposed world the exclusion goes on at quote time, automatically, with a plain
sentence next to it: "This price excludes roof surface damage from wind and hail. If the
roof was fully replaced in the last 20 years, check here and we will remove it." The agent
either accepts the exclusion and binds today, or attests and binds today without it. No
referral. If an inspection later shows the attestation was false, the cancellation is on
the record the agent gave us, not on a surprise we never asked about.

## The problem

- The dwelling age alert (101+ year old homes) drives 70-80% abandonment. Killing it is
  worth roughly 115-175 net new binds, but eating ~25 incremental knocks, and underwriting
  has said knocks are deadly (Darren: three knocks can lose an agent for life).

> **Codex review 2026-09-23:** CANNOT VERIFY. The age-alert abandonment and incremental bind/cancellation estimates lack their source populations, windows and uncertainty; see also P2 and P3. See REVIEW-2026-09-23.md #P1.

- The single most common thing underwriters actually do on these referrals is apply the
  roof surfacing exclusion by hand (~1,018 times in the May 1 to Aug 15 bound 101+ book).

> **Codex review 2026-09-23:** CORRECTED. The first read reports 1,018 inferred hand-excluded dwellings in May 1-Aug 15, or about 291 per month; the ranking of UW actions is not established. See REVIEW-2026-09-23.md #P4.

- Today's automation is set very conservatively (roughly the worst 5-10% of roofs) and
  provides effectively no cancellation protection: the model said "exclude" on 0 of the
  106 roof-cancelled homes in the April+ book.

> **Codex review 2026-09-23:** CORRECTED. Live issued and retained-NB checks confirm zero model-exclude decisions among 106 all-age snapshot cancellation policies; only nine contain a 101+ home. This does not measure cancellation prevention. See REVIEW-2026-09-23.md #P6.


So the alert exists largely to route homes to a human who applies an exclusion a model
could apply. If the model applies it, one big reason for the alert goes away.

## What we build

1. **A wider bar, only for 101+ homes.** A sub-rule on the existing auto-exclusion model:
   for dwellings 101+ years old, apply the roof surfacing exclusion at a lower score bar.
   Candidate settings, priced on the bound 101+ book (RESULTS-2026-08-20.md, corrected 8/21):
   - Bar 85: captures 50.7% of hand-applies, ~123 over-applies/mo, 0.83 over-applies per catch.

> **Codex review 2026-09-23:** CORRECTED. The printed 0.83 is a running average; the step from bar 90 to 85 is 185 additional left-alone exclusions per 122 additional workflow catches in the May 1-Aug 15 bound 101+ book. See REVIEW-2026-09-23.md #P7.

   - Bar 83 (the bottom-20% cut Will and I discussed): captures 54.7%, ~151 over-applies/mo,
     roughly 1:1 over-applies per catch (0.95).

> **Codex review 2026-09-23:** CORRECTED. The step from 85 to 83 adds 99 left-alone exclusions for 41 extra catches, or 2.41 per catch, in the May 1-Aug 15 bound 101+ dwelling book; P80 on eligible traffic remains unverified. See REVIEW-2026-09-23.md #P8.

   - The bar is a decision, not a fact. The marginal cost step is 1.52 at 85 and 2.41 at 83,
     and no setting is defensible until underwriting supplies the exchange rate: what one
     caught roof is worth against one unwanted exclusion. That ask is open (DECISION-MATRIX.md).

> **Codex review 2026-09-23:** CONFIRMED. R is still a gate, but the cited file exists only at origin/decision-matrix:DECISION-MATRIX.md and the step estimates lack clustered intervals. See REVIEW-2026-09-23.md #P11.

2. **The escape hatch (this is the new part).** When the exclusion is auto-applied, the
   agent sees one yes/no attestation: "Has the roof been fully replaced in the last
   20 years?" Yes removes the exclusion and stamps the attestation on the quote. This is
   how we kill the false positives without a referral.
3. **Attestation-backed knocks.** If a later inspection contradicts the attestation, the
   resulting knock cites the agent's own answer. Open policy question Will asked me to take
   to Darren: are knocks acceptable when the agent has attested falsely? This is different
   in kind from today's inspection knocks, which punish things we never asked about.

> **Codex review 2026-09-23:** CORRECTED. Rename the old outcome wording to NOC; distinguish letters from cancellation transactions, and measure the attestation lane before claiming no added cancellations. See REVIEW-2026-09-23.md #P32.

4. **Keep the safeguard, lose the referral.** The alert machinery can stay as a pass-through
   (the excess-water pattern): visible, not blocking, no underwriter in the loop. "Zero
   alerts" per Will means zero referrals, not zero safeguards.

## What we do not build (yet)

- No change below age 101. Hand-applies are 4-6x rarer under 101 and the same bar costs
  2.5 to 9 over-applies per catch there.

> **Codex review 2026-09-23:** CORRECTED. The new live sweep provides age- and bar-specific counts; the quoted younger-band range is not a universal marginal cost. Use the version, age, window and step shown in the review. See REVIEW-2026-09-23.md #P12.

- No old-home-specific roof model. To be fair, we would love one, and it stays the right
  long-term answer; we do not have the resources to build it now, so this PRD leverages the
  dial we already have. Same model, wider aperture, version-pinned (v1.2.0) so the bar
  means one thing. The shadow test and pilot generate exactly the labeled 101+ outcomes a

> **Codex review 2026-09-23:** CORRECTED. Version pinning is a requirement for the proposed test; the candidate prices above pool model versions, and a sister model is a hypothesis to test. See REVIEW-2026-09-23.md #P13.

  dedicated model would train on later.
- No auto-decline and no premium change. The exclusion prices the roof out; it does not
  block the bind.

## What we know (verified)

- **The exclusion works in dollars, not in claim counts.** Excluded roofs still file wind
  and hail claims at the same rate, but the median payment is $477 against $7,523 for
  comparable non-excluded claims. Net of controls, 83% of expected roof-peril dollars go
  unpaid. About $52 of avoided paid loss per excluded home-year, measured on hand-picked
  roofs only. Do not multiply that by a wider bar's catch count; marginal roofs must avoid
  less. (LOSS-JOIN-2026-08-21.md)

> **Codex review 2026-09-23:** WITHDRAWN. The branch-only loss first read is observational and all-age, has an exposure-duplication defect and does not establish marginal 101+ savings or a causal contractual effect. See REVIEW-2026-09-23.md #P14.

- **Capture and cost at each candidate bar**: the aperture and marginal-cost tables in
  RESULTS-2026-08-20.md. Bottom-20% = bar 83 on the pooled book; must be re-derived on
  v1.2.0-only eligible traffic before it is quoted.
- **Compliance watch item**: the never-referred lane is no longer hypothetical. Today's
  conservative setting already binds ~65-70 policies per month carrying an exclusion no
  underwriter ever saw (measured Jul 2026); a bar-80 setting on 101+ was earlier projected

> **Codex review 2026-09-23:** WITHDRAWN. The current all-age lane and proposed 101+ projection use different populations and routing; the pass-through design requires a new estimate. See REVIEW-2026-09-23.md #P15.

  to add ~34 quotes/mo on top. Filings/disclosure review needed before launch.


> **Codex review 2026-09-23:** CORRECTED. Independent arithmetic checks do not justify treating every interpretation as confirmed. See REVIEW-2026-09-23.md #P30.

## What we measured on 2026-08-25 (all three adversarially verified, all CONFIRMED)

1. **Bind-rate impact: small, maybe zero.** (BIND-RATE-2026-08-25.md) On 47,435 101+ quotes
   Apr 1 to Aug 11, what decides bind is the referral gate, not the exclusion: never-referred
   101+ quotes bind ~1% with or without it. After an underwriter approves, quotes with the
   exclusion bind 41.8% vs 48.0% without, but on equally-bad roofs (score 90+) the gap
   collapses to 44.9% vs 46.4% and is statistically indistinguishable. Honest bracket for
   the exclusion's own bind cost on an approved quote: between about 0 and 6 points, best
   estimate 1.5 to 5, not distinguishable from zero at current volumes. The auto-exclusion
   does not scare agents off pre-referral either: score-matched auto-excluded quotes get
   referred nearly twice as often (37.8% vs 20.8%) and bind more end to end (9.7% vs 5.9%).

> **Codex review 2026-09-23:** WITHDRAWN. Restoring hand exclusions to the non-auto comparator reverses the printed 90+ bind comparison to 11.92% non-auto versus 9.68% auto for Apr 1-Aug 11 101+ quotes; the approval comparisons remain selected associations. See REVIEW-2026-09-23.md #P18.

2. **Over-applying has cost almost nothing measurable so far.** (OVERAPPLY-COST-2026-08-25.md)
   The live auto lane binds at the same rate as the old hand lane (11.3% vs 10.8%, p=0.47);
   worst-case score-matched bind drag is 1.4 points. Post-bind pushback: 9 of 436
   auto-applied exclusions removed after bind (2.1%, about 2.5x the hand rate, borderline
   significance), and all 9 stayed off rather than being fought back on. The real growing
   cost is the compliance lane: ~65-70 bound policies per month now carry an exclusion no
   underwriter ever saw (66% of auto-exclusion binds in July). And the benefit side on
   marginal roofs is UNMEASURABLE until ~spring 2027: 24 of the 25 excluded-book wind/hail
   claims predate the roof score.

> **Codex review 2026-09-23:** CORRECTED. The all-age raw removal comparison is 9/436 versus 29/2,774, or 1.97x; the 2.53x comparison instead uses 6/254 versus 18/1,931 with 45-day follow-up, and the bind point estimate is not a worst-case bound. See REVIEW-2026-09-23.md #P21.

3. **Yes, we knock excluded homes more, and not for the roof.** (NOC-RATES-2026-08-25.md)
   Hand-excluded 101+ homes take all-cause knocks at 16.1 per 100 home-years vs 10.6 for
   same-age homes without; age/state/vintage-standardized 1.59x (CI 1.38-1.83). Removing
   roof-reason knocks barely moves it (1.49x): the exclusion marks generally distrusted
   properties, it does not save the relationship. This is selection, not cause; part could
   be surveillance (excluded homes get inspected more). The auto lane is too young to read
   (0 knocks in the first 60 days on 186 policies); re-pull ~October.

> **Codex review 2026-09-23:** CORRECTED. Within the historical 101+ oldest-home policy band, roof-coded transaction rates are about 1.95x higher; compare crude 1.49 with crude 1.52, and label the zero-auto count as a 60-day result. See REVIEW-2026-09-23.md #P23.


**What the three together mean for this PRD**: the acceptance risk that was the pilot's
main worry looks small (1), the live over-application experiment has been cheap (2), but
an exclusion is not a substitute for the knock, so killing the dwelling age alert via the
wider dial does not remove the knock exposure on these homes (3). The bind upside case
survives; the "no incremental knocks" claim needs the attestation lane to carry it.

> **Codex review 2026-09-23:** WITHDRAWN. Bind upside and no-incremental-NOC conclusions need a controlled pilot and measured attestation behavior. See REVIEW-2026-09-23.md #P25.


## Open decisions (blockers before build)

1. **The exchange rate.** Underwriting supplies R (one caught roof vs N unwanted
   exclusions). Without it no bar can be chosen. Owner: Suph to Darren/LaNae.
2. **LaNae's tolerance has still not been asked.** This is the standing gate on the whole
   Zero Alerts program.
3. **Knocks-on-a-lie.** Darren/underwriting position on attestation-backed knocks.
4. **Bar menu**: 85 vs the 80-83 bundle. Decided by 1, informed by the in-flight analyses.

> **Codex review 2026-09-23:** CORRECTED. Replace the in-flight status description with explicit evidence and remaining gates. See REVIEW-2026-09-23.md #P30.

5. **Compliance/filings** sign-off on the never-referred lane.

## Rollout shape (proposed)

1. Version-pinned shadow test on 101+ homes first: log what the wider bar would have done,
   no customer impact. Re-derive the bottom-20% point on v1.2.0 eligible traffic.
2. Fix the known config anomaly first: the automation has never fired in Texas (0
   auto-applies since the May 11 launch). Check with the model owner.

> **Codex review 2026-09-23:** WITHDRAWN. Current TX May 11-Aug 11 quote-home rows include 16 selected exclusions among 17 flag-on/exclude 101+ rows, all Draft. A bound-old-home zero is narrower; actor and eligibility remain unresolved. See REVIEW-2026-09-23.md #P26.

3. Pilot reads come from CA/NJ/PA (they dominate the launch-state 101+ book; Texas is too
   thin at 52 bound 101+ dwellings per quarter).

> **Codex review 2026-09-23:** CORRECTED. The source reports 52 bound 101+ dwellings over May 1-Aug 15 2026, or 3.5 months, not a quarter; rollout history and volume are separate criteria. See REVIEW-2026-09-23.md #P27.

4. Pilot success is measured on acceptance, not on loss: bind rate, abandonment,
   attestation rate, override/removal requests, complaints. The loss join already
   establishes the exclusion's contractual bite; the open question is whether agents and
   customers take the deal.

> **Codex review 2026-09-23:** WITHDRAWN. The loss association does not establish the causal contractual effect; acceptance and loss validation both remain open. See REVIEW-2026-09-23.md #P14.


## Risks

- Selection: everything measured so far is on underwriter-picked roofs; the wider bar hits
  marginal roofs whose benefit is lower and whose owner pushback may be higher.
- Attestation abuse: if "yes" is free and unaudited, the escape hatch swallows the rule.
  Mitigation is the inspection-backed knock, which is exactly the open policy question.
- The exclusion may not remove the alert on its own: it addresses ~half of what
  underwriters do on dwelling age referrals. Pre-fill quality (bake-off, separate track)

> **Codex review 2026-09-23:** CANNOT VERIFY. No action census establishes that roof exclusions address half of UW work on dwelling-age referrals. See REVIEW-2026-09-23.md #P29.

  and the historic-district attestation cover the rest.

> **Codex review 2026-09-23:** CORRECTED. Direct aggregate warehouse reruns and their limitations are recorded with query files and output counts. See REVIEW-2026-09-23.md #P6, #P26 and #P31.
