# roof-dial

## Takeaways from the first read

**Use 83 as the balanced starting bar for the old-home proposal, with the roof-replacement escape hatch.** The follow-up now checks every integer threshold and gives 83 an explicit mathematical case. This recommendation assumes a useful retained exclusion is worth roughly one to two times the net cost of an extra persistent restriction; that range is a working assumption, not a measured dollar value.

A lower bar automatically adds roof exclusions to more homes. The escape hatch can reduce the cost by removing exclusions after an agent attests to full roof replacement in the last 20 years. The calculation must count both extra restrictions removed and useful protection removed.

- **83 survives the full comparison.** On the recent bound-home sample, it is the best integer bar when the value-to-cost ratio after the hatch is about 1.30-1.91. It also minimizes the worst missed value over the assumed range 1-2.
- **The original reason for 83 was different.** It marked roughly the worst 20% of the old mixed-model bound book. It now selects 23.4% of current quote-homes; about 20% would be bar 85, or 86 for a strict cap.
- **83 matches about half of the historical manual exclusions.** If the goal is to match at least 80%, the recent bound-home proxy requires bar 66 before the hatch. That is a much broader proposal.

### What changing the bar costs

In the recent model-v1.2.0 bound sample:

| Bar | Historical manual exclusions matched | Extra restrictions on previously unrestricted homes |
|---:|---:|---:|
| 85 | 134 of 295, or 45.4% | 97 |
| **83** | **162 of 295, or 54.9%** | **125** |
| 80 | 186 of 295, or 63.1% | 175 |

**85 to 83 buys 28 more matches for 28 extra restrictions. Going from 83 to 80 buys another 24 matches for 50 extra restrictions.** These are before the escape hatch. A simulation removing only selections with CAPE-recorded recent roof years leaves 146 matches and 105 extra restrictions at 83, and still selects 83 at an assumed value-to-cost ratio of 1.5. Most remaining roof years are unknown, so this is not an estimate of actual agent answers.

The recent sample covers new-business creations July 30-August 31, 2026, home age 101+, model v1.2.0, excluding CO/RI/WV, with issue observed before September 23. Who applied an exclusion is inferred from current records. These are historical coverage comparisons, not a rollout forecast, verified roof labels, or measured dollar costs. The [decision memo](THRESHOLD-DECISION-2026-09-23.md) separates bound-home comparisons from all-quote prompt volume.

### What we should do next

**Start with 83; use measured hatch outcomes to decide whether to move toward 80.** A sufficiently selective hatch can make 80 better. Financial value, customer response and actual attestation accuracy remain unmeasured. Sampling uncertainty also remains: 83 wins 45.55% of 2,000 policy resamples at the assumed ratio 1.5, so the exact score is not settled for all future traffic.

Removing the dwelling-age referral is a shared part of the PRD at every bar. Count its workflow benefit once; each extra coverage match is not automatically another underwriting review saved.

Read [the number, its math, and when it changes](THRESHOLD-DECISION-2026-09-23.md), the [full integer results](review/threshold_empirical.md), or the [escape-hatch evidence](review/threshold_escape_hatch.md). The earlier [independent audit](REVIEW-2026-09-23.md) remains available for the full claim ledger.

### Reproduce the current decision math

These commands use the saved aggregate query results and require only Python 3:

```sh
python3 review/threshold_decision_math.py
python3 -m unittest discover -s tests -p 'test_threshold_decision_math.py'
```

The SQL and run logs document the separate warehouse queries. The script recomputes the full threshold comparisons and hatch scenarios; it does not refresh the warehouse data.

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
