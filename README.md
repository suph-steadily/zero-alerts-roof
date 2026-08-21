# roof-dial

Job 1 of the dwelling alert project: where should the automatic roof surfacing exclusion's score bar sit? **`SCOPE.md` is the document to read (and share)**; the presentable version is the shared page: https://claude.ai/code/artifact/f04c8819-6ab0-4912-86c3-4f3328acadb0. This folder also carries the extract SQL, the verification queries behind every headline number (`sql/probes_20260820.sql`), and a runnable sweep tool.

> **Status 2026-08-21.** The results memo was corrected after a senior data-science pressure test. Three headline numbers are withdrawn (the "defensible band" framing, the whole-book harm-prevention shares, and the Phase 3 false-positive share) and two arithmetic slips are fixed; `sql/03` should not be run for quotable output. Read the **Corrections** section at the end of `RESULTS-2026-08-20.md` before using any figure from this folder, and note that reproducibility is partial: the checked-in SQL is age 80+ from April with no end date, while the memo's primary curve is 101+ over May 1 - Aug 15, and several tables live only in the agents' run logs.

## Run it

No dependencies, plain built-in Python 3 (nothing to install). From this folder:

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

## Tests

```
python3 -m unittest discover -s tests
```

The 2026-08-20 probe numbers are pinned as tests: the banded example must reproduce the preview curve (36.1% capture at 91+, 58.8% at 81+, 74.5% at 71+, 82.3% at 61+) exactly. Added 8/21: the marginal step costs off the memo's own Phase 1 counts (0.85 onto 90, 1.52 onto 85, 2.41 onto 83, 2.52 onto 80) are pinned too, so the running average cannot be mistaken for the cost of moving the bar again.

## Layout

- `SCOPE.md` - the scope: question, verified data inventory, the four measurements, phases, decision framing
- `sql/` - the three warehouse extracts (Metabase db 235, read-only), verified 2026-08-20; each header now carries its known limits from the 8/21 review, and `03` is marked withdrawn
- `roof_dial/` - the sweep tool: `sweep.py` (the aperture curve), `overlay.py` (harm overlay + over-apply disposition), `report.py` (markdown tables), `__main__.py` (CLI)
- `examples/bound_101plus_bands_20260820.csv` - real banded counts from the probe, so the demo runs with zero setup
- `tests/` - the probe numbers, pinned
