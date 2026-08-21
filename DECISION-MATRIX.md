# Roof dial: the decision matrix (2026-08-21)

*Phase 4 of the roof-dial scope: the priced options, laid out for underwriting to pick.
Every number comes from the corrected results memo ([RESULTS-2026-08-20.md](RESULTS-2026-08-20.md),
post-8/21 corrections); nothing withdrawn on 8/21 appears here. Population and windows as in
Phase 1 unless stated: bound NB 101+ dwellings created May 1 - Aug 15, 2026 (3.5 months),
pooled across model versions.*

**Status: these are candidates for a version-pinned shadow test, not production settings.**
The matrix prices the options; it never picks one. Underwriting sets the dial — and the
one input only underwriting can supply is the exchange rate.

## 1. The decision, stated properly

The curve has no knee — no point where the math stops you *(the 8/21 correction)*. So the
bar cannot be chosen from the data alone. It follows mechanically from one number:

> **The exchange rate R: how many unwanted exclusions is one caught home worth?**
> R = 1 means you would trade one-for-one. R = 2.5 means a caught home is worth
> 2.5 exclusions an underwriter would have left alone.

Given R, the rule is: **keep widening the bar while the next step down costs less than R
over-applies per extra catch.** The marginal curve then hands you the bar:

| if underwriting's R is… | the bar is | because the next step down costs |
|---|---|---|
| below 0.85 | 95 | 0.85 (onto 90) — already too dear |
| 0.85 to 1.52 | 90 | 1.52 (onto 85) |
| 1.52 to 2.41 | 85 | 2.41 (onto 83) |
| 2.41 to 2.52 | 83 | 2.52 (onto 80) |
| 2.52 to 2.75 | 80 | 2.75 (onto 75) |
| above 2.75 | below 80 — re-price first | steps steepen: 3.50, 4.52, 6+ |

Two honest notes on this table:

- **Bar 83's window is razor-thin (2.41 to 2.52).** The bottom-20% cut is a *capacity*
  heuristic — "automate the worst fifth of the book" — not a marginal-cost sweet spot. It
  survives as a candidate only on the capacity argument, and the 20% point must be
  re-derived on v1.2.0-only eligible traffic before it is quoted.
- **These windows sit on the pooled bound-survivor curve.** The v1.2.0-only cut (priced at
  bar 80 alone: 0.87 over per catch vs 1.10 pooled) says the true windows will move. The
  version-pinned re-cut is what firms them up.

R does not exist yet anywhere in the dwelling-alert framework — the tolerance is recorded
as unset. **Supplying R (even as a range) is the decision ask.** And because the lived cost
of an over-apply is still unmeasured (exactly 1 post-bind removal of an auto-applied
exclusion so far; the pushback re-pull lands ~October), R is set on judgment today and
audited by the shadow test and the October re-pull.

## 2. The matrix

Per-month figures divide the 3.5-month bound-book counts (the memo's other base, the
censored Aug 1-15 go-forward pool, runs about half these at bar 80 — quote one, say which;
this matrix uses the bound-book base throughout).

| | **status quo** | **bar 90** | **bar 85** | **bar 83** (bottom-20% cut) | **bar 80** |
|---|---|---|---|---|---|
| capture of the 1,018 hand-applies | 5.5% of total exclusion work* | 38.7% (394) | 50.7% (516) · CI 47.6-53.8 | 54.7% (557) · CI 51.6-57.7 | 60.7% (618) · CI 57.7-63.7 |
| catches/mo | ~14 (go-fwd) | 113 | 147 | 159 | 177 |
| over-applies/mo | ~0 | 70 | 123 | 151 | 195 |
| marginal cost of the step down to here | — | 0.85 (from 95) | 1.52 (from 90) | 2.41 (from 85) | 2.52 (from 83) |
| exchange-rate window where this is the stop | R < 0.85† | 0.85-1.52 | 1.52-2.41 | 2.41-2.52 | 2.52-2.75 |
| never-referred compliance lane | ~0 | share not sized | 40% of over-applies (per-month not sized) | not sized | ~35% ≈ **~34 quotes/mo** (soft; go-fwd base) |
| roof-cancelled homes (of 106) the setting would have seen | **0** | 22 visible at bind‡ | 30‡ | 38 scored 83+‡ | 47‡ |

\* *Status quo is not "bar 95."* The live decision uses non-score inputs and fired on 59 of
1,077 exclusions in the window (5.5% of the total exclusion work, ~14/mo go-forward) — far
below what a plain bar-95 rule would catch (227, ~65/mo). It also applied the exclusion on
**0 of the 106 roof-cancelled homes, including all 12 that scored 95+**: effectively no
cancellation protection at today's setting.

† Strictly "stay at 95"; steps above 95 were not priced.

‡ *Visibility, not prevention*, and **whole-book numbers** (the extract has no age filter):
a 101+-only rule reaches only the 101+ subset, and on already-reviewed 101+ binds only ~27%
of post-bind leaks scored 80+. The with-exclusion vs without comparison is association only
(Fisher pooled p = 0.078) and partly definitional — an excluded roof has little left to
cancel for. Do not quote this row as prevented cancellations.

## 3. What this matrix cannot tell you

Carried over from the corrected memo, so nobody re-learns them:

1. **Survivor sample.** The curve is built on bound quotes; the exclusion goes on before
   bind and can change whether a quote binds. Monthly over-apply volume is likely
   understated.
2. **Capture measures imitation, not accuracy.** "Hand-apply vs left alone" is a label of
   today's workflow; underwriters will also adapt once the automation widens.
3. **Pooled across model versions.** Only bar 80 has a v1.2.0-only price. The re-cut
   decides whether 83 survives as the capacity point and where the windows land.
4. **No prevention estimate exists.** Nothing here demonstrates that applying the exclusion
   prevents harm; the sharper pilot question is acceptance (bind rate, abandonment,
   overrides, removals, complaints) and whether exposure falls or merely moves into the
   contract.
5. **Over-apply cost is a count, not a verdict** until the October pushback re-pull.

## 4. Gates before any bar reaches production

| # | gate | owner | status |
|---|---|---|---|
| 1 | Exchange rate R set (even as a range) | underwriting | **the ask** |
| 2 | Version-pinned, decision-time Phase 1 re-cut (v1.2.0, all eligible quotes, 20% point re-derived) | analysis | open — decides if 83 survives |
| 3 | Shadow test at the chosen candidate(s), 101+ only, version-pinned | analysis + model owner | scoped, not started |
| 4 | Compliance/filing sign-off on the never-referred lane (~34/mo at bar 80) | compliance | open watch-item |
| 5 | Translation into the shipped rule (non-score inputs; check the Texas zero-fire) | model owner | open |
| 6 | Curry photo session, 10-20 quotes just above the candidate bar | Curry's team | open |

## 5. The ask, in one paragraph

Underwriting supplies R — or a range, which may be enough: any R between 1.52 and 2.41
points at 85, anything just past 2.5 points at 80, and 83 needs a nearly exact 2.4-2.5 or
the capacity argument. With R in hand, approve the shadow test on the implied bar (bracket
it with a neighbor if R sits near a boundary), and the version-pinned re-cut plus the
October pushback re-pull turn today's judgment into a measured setting.
