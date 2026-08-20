# Roof dial: scope for the aperture analysis

*Job 1 of the dwelling alert project: duplicate the underwriter's roof surfacing exclusion work. Scoped 2026-08-20; every data claim below was verified against the warehouse that day (Metabase db 235, read-only probes).*

## 1. The question

Today the automation applies the roof surfacing exclusion only when the roof score model says "exclude", which happens on about 4 of 100 old-home referrals. Underwriters hand-apply the same exclusion far more often. One dial controls the gap: the score bar (roof score runs 1 to 100, higher is worse; the model today fires around the mid-90s).

**This project answers: where should the bar sit so the automation captures a good share of the exclusions underwriters would have applied, without excluding many roofs an underwriter would have left alone?** Laid out on a curve: capture rate on one axis, over-applies on the other, one point per candidate bar. Underwriting picks the operating point; this analysis prices the options.

## 2. What the 8/20 probes verified

**The pool is big and hand-dominated.** On bound new-business 101+ homes created May 1 to Aug 15, 2026: 1,077 dwellings carry the exclusion, of which 59 were auto-applied (5.5%) and 1,018 were hand-applied by an underwriter (94.5% — agents cannot set this coverage). After the July 30 nationwide expansion, the go-forward catchable pool is the "flag on, automation did not fire" lane: roughly 80 to 120 hand-applies per month in 101+ alone.

**A score bar can separate them.** Hand-applied roofs score far worse than left-alone roofs (median 85 vs 45 on bound 101+). Only 8 of 1,018 hand-applies (0.8%) have no score at all, so almost nothing is invisible to a bar. Example sweep on the bound 101+ book (dwelling counts, May 1 to Aug 15; denominators: 1,018 hand-applied, 4,404 left-alone):

| bar | captures (of 1,018 hand-applies) | over-applies (of 4,404 left-alone) | over-applies per catch |
|----|----|----|----|
| 91+ | 367 (36.1%) | 214 (4.9%) | 0.58 |
| 81+ | 599 (58.8%) | 632 (14.3%) | 1.06 |
| 71+ | 758 (74.5%) | 1,076 (24.4%) | 1.42 |
| 61+ | 838 (82.3%) | 1,524 (34.6%) | 1.82 |

(These are banded preview numbers from the probe, reproduced by `python3 -m roof_dial example`. The real Phase 1 curve sweeps finer bars and cuts by age band, state, and model version.)

**The post-bind outcomes join back to bind-time scores, 100% match.** Preview: of underwriter endorsements that added the roof exclusion after bind (April+ binds, 90-day window), 69% had a bind-time score of 60+ (434 of 633). Of "Condition - Roof" cancellations, 73% (80 of 110). A wider bar would have handled most of the post-bind roof harm before bind. This matters because the roof surfacing exclusion alone is 53 to 59% of all UW corrective NOEs.

**Two hard limits, stated up front:**
- **Scores exist only on April 2026+ binds** (the model shipped mid-March). Jan to Mar is unusable for the score axis; the backtest runs on the April+ book.
- **The live "exclude" decision is not a pure score cut.** Recorded excludes span scores 1 to 97, so the model uses inputs beyond the score (likely imagery confidence). This analysis prices a plain score bar, which is the sizing tool. Retuning the live model to a chosen operating point is an implementation step with the model's owner, and the numbers may shift slightly there.

## 3. The four measurements

**3a. The aperture curve.** Population: bound new-business quotes created April 1, 2026 onward, dwelling age 80+. At each bar T (sweep 55 to 95 in steps of 5):
- *Catch* = a hand-applied exclusion whose dwelling scored at or above T. Catch rate names its denominator: per 100 hand-applied exclusions on bound quotes in the window, unscored ones included.
- *Over-apply* = a left-alone bound dwelling at or above T. Reported three ways: share of the left-alone book, over-applies per catch, and absolute over-applies per month.
Cut by age band (80-90 / 91-100 / 101+), by state (Texas separately, longest bake), and with the score model version pinned to v1.2.0 plus a pooled sensitivity check (v1.1.5 ran alongside it into the spring).

**3b. The harm overlay.** At each bar: the share of post-bind roof NOEs (underwriter adds the exclusion after bind, 90-day window, per 100 bound) and Condition - Roof NOCs that had a bind-time score at or above the bar, i.e. the harm a wider bar would have prevented. Roof NOEs land a median 35 to 38 days after bind, so a 60-day window gives a fair early read where the 90-day runway is not complete yet.

**3c. The over-apply disposition (the honest false-positive count).** "The model would exclude where the underwriter chose not to" is not automatically a mistake. Each over-apply gets classified:
- *(a) late catch* — that home drew a roof NOE or roof NOC within 90 days anyway; the automation was right early
- *(b) true disagreement* — an underwriter reviewed the quote and left the roof alone
- *(c) presumed false positive* — never reviewed by an underwriter, clean at 90 days
Plus a hand review of 10 to 20 quotes sitting just above the candidate bar, with Curry's team, to sanity-check what (c) looks like in real photos.

**3d. The pushback lane.** Removals of the exclusion after bind (agents or customers objecting) are the lived cost of over-applying. Today this is unmeasured on the auto era: exactly 1 auto-applied exclusion has been removed post-bind, because the April/May waves have barely any outcome runway yet. Scheduled re-pull around October when June and July binds mature. Until then, over-apply costs stay a count, not a verdict.

## 4. Population and hygiene rules

- Bound new-business quotes, `pol_created_timestamp` from April 1, 2026 (the score era); never `policy_original_created_timestamp` (renewal trap).
- Dwelling grain; aggregate to quote level where stated (about 1.16 dwellings per quote).
- Exclusion tested with `= 'selected'` (string column; boolean-style tests read false on everything).
- Year built guarded `> 1700` (zero-default integer; 25 quotes affected in the probe window).
- Exclude Apr 27-28 (NJ/AZ pause) and May 29 (aborted all-states flip) from any before/after comparison.
- After July 30 the flag is on nationwide, so hand-applies from August onward are true "automation did not fire" cases; May to July mixes flag-on and flag-off states, which the state cut handles.
- 90-day outcomes are complete for binds through about May 22 (as of Aug 20); later binds use the 60-day window or wait.
- Rates always name their denominator and window. "NOC" and "NOE" follow the house definitions (transactions, not letters).

## 5. Verified data inventory

Everything Phase 1 needs lives on **`dbt.ipod_standard_mga_raw_policy_info`** (one row per quote version x dwelling):

| column | what it is | verified |
|---|---|---|
| `pol_prop_steadily_roof_condition_score_condition_score` | the score, 1-100, higher worse; nullable | 99.6% coverage on bound quotes |
| `pol_prop_steadily_roof_condition_score_decision` | the model's call: '', 'pass', 'alert', 'exclude' | all four values confirmed; excludes span 1-97 |
| `pol_prop_steadily_roof_condition_score_model_version` | v1.1.3 through v1.2.0 | v1.2.0 dominant; pin or stratify |
| `pol_ff_automated_roof_exclusion` | flag state at creation: '', 'no', 'yes' | wave dates reproduce from it |
| `prop_cov_roof_surfacing_exclusion` | the exclusion on the quote: '' or 'selected' | beware three near-duplicate column names |
| `quote_status` / `quote_issued_timestamp` | bound = 'Issued' (identical to timestamp non-null) | exact match on 44,073 rows |
| `pol_prop_year_built`, `quote_type`, `pol_created_timestamp`, `policy_id`, state | cohort cuts | verified |

Post-bind outcomes: the 8/16 snapshot tables (`dbt_dev.damr_uarnoe_cohort/final/evdetail_20260816`) already classify events and actors; the roof-add event is `e_col='roof_surfacing_exclusion'`, `e_prev=''`, `e_cur='selected'` in the detail table, and the NOC sub-reason string is exactly `'Condition - Roof'`. Caution: 9 roof-add events carry a different event class, so go through the detail table, not the class column alone. The snapshots cover Jan-May creations only and only three cohort slices; Phase 2 rebuilds the cohort for all April+ binds age 80+ using the documented recipe (`~/mockups/damr-postbind-uarnoe/ANALYSIS-2026-08-16.md`); the machinery is population-agnostic, only the cohort WHERE clause changes.

Dead end, recorded so nobody re-walks it: `dbt_data_science.fct_roof_exclusion` is an older study built on CAPE vendor ratings (dirty values, epoch-zero dates), has no Steadily score, no decision, no flag, and does not track who applied the exclusion. Its only salvage value is `roof_uw_action_count` as an independent cross-check of "an underwriter touched this roof".

## 6. Phases

| phase | what | effort |
|---|---|---|
| 1 | The aperture curve on the bound book (extract via `sql/01`, sweep via `roof_dial`) | 1-2 days |
| 2 | Harm overlay: rebuild the post-bind cohort for April+ binds age 80+, join to bind scores (`sql/02`) | 1-2 days |
| 3 | Over-apply disposition (`sql/03`) + the Curry photo session | 1 day + one sit-down |
| 4 | Texas-first read, then the proposal: 3 or 4 priced bars including the bottom-20% idea, underwriting picks | 2-3 days |
| later | Pushback re-pull (~Oct), and feeding the chosen bar into the alert-removal case | small |

## 7. Decision framing and watch-items

- **Underwriting sets the dial.** The analysis prices settings; it never picks one. The named starting proposal is Curry's bottom-20% idea; price it as one of the candidate bars.
- **Texas first.** Longest model bake (live May 11). If widening works, Texas shows it first; check the manual-rate drop there before generalizing.
- **Compliance lane, measured explicitly.** Auto-exclusions on quotes no underwriter ever saw grew from 0.4% to 5.0% of never-referred 101+ quotes in launch states. A wider bar grows this lane mechanically. Size it at each candidate bar and flag it (disclosure and filing implications; CO/RI/WV stay off, and CO/KY/GA image-vintage rules land 1/1/2027).
- **The curve is a snapshot of current underwriter behavior.** If the automation widens, underwriters will adapt; the catch rate is measured against how they behave today, and step 6 of the playbook (prove it with the alert still on, watch the override rate) is what protects against drift.
- **Floors, not ceilings.** Post-bind harm rates on unreviewed books are floors: the alert also scares off some bad risks before bind.

## 8. What lives in this folder

- `sql/01_bound_book.sql` — the Phase 1 extract (bound book with scores, flags, exclusions)
- `sql/02_postbind_roof_outcomes.sql` — the Phase 2 outcome events joined to bind scores (runs on the 8/16 snapshots today; re-point after the cohort rebuild)
- `sql/03_overapply_disposition.sql` — the Phase 3 classification pull
- `roof_dial/` — the sweep tool: stdlib Python, no installs, reads the extracts, prints the curve tables with named denominators (`python3 -m roof_dial --help`)
- `examples/` — real banded counts from the 8/20 probe, so the tool demos with zero setup
- `tests/` — the example numbers are pinned as tests (`python3 -m unittest discover -s tests`)
