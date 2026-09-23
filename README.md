# roof-dial

## Takeaways from the first read

**Lowering the bar is worth testing. We have not shown that 83 is the best setting or that adding more exclusions will leave sales unchanged.**

A lower bar would automatically add a roof coverage exclusion to more homes. That could handle more of the work done manually today, but it would also restrict coverage on homes that previously had no exclusion.

- **The idea still looks promising.** The updated sample using model v1.2.0 shows fewer extra exclusions per additional manual decision matched than the earlier sample that mixed model versions.
- **83 is a candidate, not a settled choice.** The evidence does not clearly distinguish it from nearby settings such as 85.
- **The financial cost is still unknown.** We can count extra coverage restrictions. We cannot yet reliably say how many sales they would lose or how much money they would save in claims.

### What changing the bar costs

In the updated sample, **moving from 85 to 83 matches 38 more exclusions recorded as manually applied, while adding exclusions to 56 homes that previously had none.** That is about **1.5 extra coverage restrictions per additional manual decision matched**, compared with 2.4 in the earlier mixed-model sample.

This is a historical example, not a rollout forecast. It covers bound new-business homes aged 101+ (2026 minus year built), created May 1-August 15, 2026, using model v1.2.0, rechecked September 23. The samples differ, and who applied each exclusion is inferred from the records. Matching a manual coverage decision does not necessarily remove the whole underwriting review.

### What we should do next

**Run a limited test comparing 85 and 83 before choosing a setting for a broader rollout.** Measure whether underwriting work actually falls, whether fewer customers buy, and how agents use the roof-replacement answer that removes the exclusion. Use those measurements to decide whether the extra automation is worth the extra coverage restrictions.

Read the [plain-English review summary](REVIEW-2026-09-23.md#plain-english-takeaway), the [bar calculations](REVIEW-2026-09-23.md#RS3), or the [remaining work](REVIEW-2026-09-23.md#prioritized-redo-list).

## Earlier context and run instructions

The material below preserves the earlier first read and its review notes. Start with the takeaways above for the current recommendation; the older figures and demo commands are historical evidence, not a rollout forecast.

Job 1 of the dwelling alert project: where should the automatic roof surfacing exclusion's score bar sit? **`SCOPE.md` is the document to read (and share)**; the presentable version is the shared page: https://claude.ai/code/artifact/f04c8819-6ab0-4912-86c3-4f3328acadb0. This folder also carries the extract SQL, the verification queries behind every headline number (`sql/probes_20260820.sql`), and a runnable sweep tool.

> **Codex review 2026-09-23:** WITHDRAWN. The probes do not emit every headline; the review records aggregate live reruns and the remaining decision-time gaps. See REVIEW-2026-09-23.md #R2.

> **Status 2026-08-21.** The results memo was corrected after a senior data-science pressure test. Five claims are withdrawn, including the "defensible band" framing, the whole-book harm-prevention shares, and the Phase 3 false-positive share and two arithmetic slips are fixed; `sql/03` should not be run for quotable output. Read the **Corrections** section at the end of `RESULTS-2026-08-20.md` before using any figure from this folder, and note that reproducibility is partial: the checked-in SQL is age 80+ from April with no end date, while the memo's primary curve is 101+ over May 1 - Aug 15, and several tables live only in the agents' run logs.

> **Codex review 2026-09-23:** CORRECTED. This is a first read; the August 25 memos and PRD add material evidence and unresolved branch-only dependencies. See REVIEW-2026-09-23.md #R1.

## Run it

No dependencies, plain built-in Python 3 (nothing to install). From this folder:

> **Codex review 2026-09-23:** WITHDRAWN. This recipe omits bar83, mixes month bases, counts overlay event rows and still emits the withdrawn disposition class. See REVIEW-2026-09-23.md #R4.

```
# zero-setup demo: the preview curve from the 8/20 probe counts
python3 -m roof_dial example

# the real thing, once the extracts are pulled from Metabase (db 235):
#   sql/01_bound_book.sql            -> bound_book.csv
#   sql/02_postbind_roof_outcomes.sql -> outcomes.csv
python3 -m roof_dial sweep bound_book.csv --months 4.5 -o curve.md
python3 -m roof_dial overlay outcomes.csv --window 90 -o overlay.md
python3 -m roof_dial disposition bound_book.csv outcomes.csv --bar 80

```

Every table prints its denominators (per 100 of WHAT, over WHAT window) and its unscored counts; nothing is dropped silently.

> **Codex review 2026-09-23:** CORRECTED. Left-alone unscored counts are not printed, and empty segment rates currently display zero. See REVIEW-2026-09-23.md #T1.

## Tests

```
python3 -m unittest discover -s tests
```

The 2026-08-20 probe numbers are pinned as tests: the banded example must reproduce the preview curve (36.1% capture at 91+, 58.8% at 81+, 74.5% at 71+, 82.3% at 61+) exactly. Added 8/21: the marginal step costs off the memo's own Phase 1 counts (0.85 onto 90, 1.52 onto 85, 2.41 onto 83, 2.52 onto 80) are pinned too, so the running average cannot be mistaken for the cost of moving the bar again.

> **Codex review 2026-09-23:** CORRECTED. These tests check copied aggregate fixtures and arithmetic, not independent warehouse evidence or the full fine-bar curve. See REVIEW-2026-09-23.md #R5.

## Layout

- `SCOPE.md` - the scope: question, verified data inventory, the four measurements, phases, decision framing
- `sql/` - the three warehouse extracts (Metabase db 235, read-only), verified 2026-08-20; each header now carries its known limits from the 8/21 review, and `03` is marked withdrawn
- `roof_dial/` - the sweep tool: `sweep.py` (the aperture curve), `overlay.py` (harm overlay + over-apply disposition), `report.py` (markdown tables), `__main__.py` (CLI)
- `examples/bound_101plus_bands_20260820.csv` - real banded counts from the probe, so the demo runs with zero setup
- `tests/` - the probe numbers, pinned

> **Codex review 2026-09-23:** CORRECTED. The layout also includes PRD.md, BIND-RATE-2026-08-25.md, OVERAPPLY-COST-2026-08-25.md and NOC-RATES-2026-08-25.md; branch references remain separate. See REVIEW-2026-09-23.md #R1.
