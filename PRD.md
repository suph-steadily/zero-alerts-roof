# PRD: Widen the roof dial, with an escape hatch

*Draft v1, 2026-08-25. Owner: Suph. Engineering partner: Will Henry (free ~Sep 1).
Workstream 1 of the Zero Alerts project (see "Do What the Underwriter Does").
Status: DRAFT. Three supporting analyses in flight, marked [IN FLIGHT] below.*

## One story first

An agent quotes a 1912 rental in Allentown. The roof model scores it 84: tired but not
terrible. Today, nothing happens at quote time. The dwelling age alert fires, the quote
goes to underwriting, and an underwriter looks at the same imagery the model scored,
applies the roof surfacing exclusion by hand, and sends it back. The agent has waited a
day, maybe two. Most agents in this spot never come back: the dwelling age alert is our
single biggest bind killer on old homes.

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
- The single most common thing underwriters actually do on these referrals is apply the
  roof surfacing exclusion by hand (~1,018 times in the May 1 to Aug 15 bound 101+ book).
- Today's automation is set very conservatively (roughly the worst 5-10% of roofs) and
  provides effectively no cancellation protection: the model said "exclude" on 0 of the
  106 roof-cancelled homes in the April+ book.

So the alert exists largely to route homes to a human who applies an exclusion a model
could apply. If the model applies it, one big reason for the alert goes away.

## What we build

1. **A wider bar, only for 101+ homes.** A sub-rule on the existing auto-exclusion model:
   for dwellings 101+ years old, apply the roof surfacing exclusion at a lower score bar.
   Candidate settings, priced on the bound 101+ book (RESULTS-2026-08-20.md, corrected 8/21):
   - Bar 85: captures 50.7% of hand-applies, ~123 over-applies/mo, 0.83 over-applies per catch.
   - Bar 83 (the bottom-20% cut Will and I discussed): captures 54.7%, ~151 over-applies/mo,
     roughly 1:1 over-applies per catch (0.95).
   - The bar is a decision, not a fact. The marginal cost step is 1.52 at 85 and 2.41 at 83,
     and no setting is defensible until underwriting supplies the exchange rate: what one
     caught roof is worth against one unwanted exclusion. That ask is open (DECISION-MATRIX.md).
2. **The escape hatch (this is the new part).** When the exclusion is auto-applied, the
   agent sees one yes/no attestation: "Has the roof been fully replaced in the last
   20 years?" Yes removes the exclusion and stamps the attestation on the quote. This is
   how we kill the false positives without a referral.
3. **Attestation-backed knocks.** If a later inspection contradicts the attestation, the
   resulting knock cites the agent's own answer. Open policy question Will asked me to take
   to Darren: are knocks acceptable when the agent has attested falsely? This is different
   in kind from today's inspection knocks, which punish things we never asked about.
4. **Keep the safeguard, lose the referral.** The alert machinery can stay as a pass-through
   (the excess-water pattern): visible, not blocking, no underwriter in the loop. "Zero
   alerts" per Will means zero referrals, not zero safeguards.

## What we do not build (yet)

- No change below age 101. Hand-applies are 4-6x rarer under 101 and the same bar costs
  2.5 to 9 over-applies per catch there.
- No old-home-specific roof model. To be fair, we would love one, and it stays the right
  long-term answer; we do not have the resources to build it now, so this PRD leverages the
  dial we already have. Same model, wider aperture, version-pinned (v1.2.0) so the bar
  means one thing. The shadow test and pilot generate exactly the labeled 101+ outcomes a
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
- **Capture and cost at each candidate bar**: the aperture and marginal-cost tables in
  RESULTS-2026-08-20.md. Bottom-20% = bar 83 on the pooled book; must be re-derived on
  v1.2.0-only eligible traffic before it is quoted.
- **Compliance watch item**: the never-referred lane is no longer hypothetical. Today's
  conservative setting already binds ~65-70 policies per month carrying an exclusion no
  underwriter ever saw (measured Jul 2026); a bar-80 setting on 101+ was earlier projected
  to add ~34 quotes/mo on top. Filings/disclosure review needed before launch.

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
2. **Over-applying has cost almost nothing measurable so far.** (OVERAPPLY-COST-2026-08-25.md)
   The live auto lane binds at the same rate as the old hand lane (11.3% vs 10.8%, p=0.47);
   worst-case score-matched bind drag is 1.4 points. Post-bind pushback: 9 of 436
   auto-applied exclusions removed after bind (2.1%, about 2.5x the hand rate, borderline
   significance), and all 9 stayed off rather than being fought back on. The real growing
   cost is the compliance lane: ~65-70 bound policies per month now carry an exclusion no
   underwriter ever saw (66% of auto-exclusion binds in July). And the benefit side on
   marginal roofs is UNMEASURABLE until ~spring 2027: 24 of the 25 excluded-book wind/hail
   claims predate the roof score.
3. **Yes, we knock excluded homes more, and not for the roof.** (KNOCK-RATES-2026-08-25.md)
   Hand-excluded 101+ homes take all-cause knocks at 16.1 per 100 home-years vs 10.6 for
   same-age homes without; age/state/vintage-standardized 1.59x (CI 1.38-1.83). Removing
   roof-reason knocks barely moves it (1.49x): the exclusion marks generally distrusted
   properties, it does not save the relationship. This is selection, not cause; part could
   be surveillance (excluded homes get inspected more). The auto lane is too young to read
   (0 knocks in the first 60 days on 186 policies); re-pull ~October.

**What the three together mean for this PRD**: the acceptance risk that was the pilot's
main worry looks small (1), the live over-application experiment has been cheap (2), but
an exclusion is not a substitute for the knock, so killing the dwelling age alert via the
wider dial does not remove the knock exposure on these homes (3). The bind upside case
survives; the "no incremental knocks" claim needs the attestation lane to carry it.

## Open decisions (blockers before build)

1. **The exchange rate.** Underwriting supplies R (one caught roof vs N unwanted
   exclusions). Without it no bar can be chosen. Owner: Suph to Darren/LaNae.
2. **LaNae's tolerance has still not been asked.** This is the standing gate on the whole
   Zero Alerts program.
3. **Knocks-on-a-lie.** Darren/underwriting position on attestation-backed knocks.
4. **Bar menu**: 85 vs the 80-83 bundle. Decided by 1, informed by the in-flight analyses.
5. **Compliance/filings** sign-off on the never-referred lane.

## Rollout shape (proposed)

1. Version-pinned shadow test on 101+ homes first: log what the wider bar would have done,
   no customer impact. Re-derive the bottom-20% point on v1.2.0 eligible traffic.
2. Fix the known config anomaly first: the automation has never fired in Texas (0
   auto-applies since the May 11 launch). Check with the model owner.
3. Pilot reads come from CA/NJ/PA (they dominate the launch-state 101+ book; Texas is too
   thin at 52 bound 101+ dwellings per quarter).
4. Pilot success is measured on acceptance, not on loss: bind rate, abandonment,
   attestation rate, override/removal requests, complaints. The loss join already
   establishes the exclusion's contractual bite; the open question is whether agents and
   customers take the deal.

## Risks

- Selection: everything measured so far is on underwriter-picked roofs; the wider bar hits
  marginal roofs whose benefit is lower and whose owner pushback may be higher.
- Attestation abuse: if "yes" is free and unaudited, the escape hatch swallows the rule.
  Mitigation is the inspection-backed knock, which is exactly the open policy question.
- The exclusion may not remove the alert on its own: it addresses ~half of what
  underwriters do on dwelling age referrals. Pre-fill quality (bake-off, separate track)
  and the historic-district attestation cover the rest.
