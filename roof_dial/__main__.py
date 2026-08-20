"""Command line for the roof dial sweep tool.

    python3 -m roof_dial example
        The zero-setup demo: reproduces the 8/20 probe preview from the
        banded counts in examples/ (bound 101+ book, May 1 to Aug 15).

    python3 -m roof_dial sweep bound_book.csv --months 3.5 [-o curve.md]
        The aperture curve from a sql/01_bound_book.sql extract.

    python3 -m roof_dial overlay outcomes.csv --window 90 [-o overlay.md]
        The harm overlay from a sql/02_postbind_roof_outcomes.sql extract.

    python3 -m roof_dial disposition bound_book.csv outcomes.csv --bar 80
        Classify the over-applies at one candidate bar.

Run from this folder (the one containing the roof_dial/ package).
"""

from __future__ import annotations

import argparse
import pathlib
import sys

from .overlay import disposition, overlay, read_outcomes
from .report import render_disposition, render_overlay, render_sweep
from .sweep import DEFAULT_BARS, read_banded, read_bound_book, sweep, sweep_banded

EXAMPLES = pathlib.Path(__file__).resolve().parents[1] / "examples"


def _bars(raw: str):
    return tuple(float(x) for x in raw.split(","))


def _emit(text: str, out: str | None) -> None:
    if out:
        pathlib.Path(out).write_text(text)
        print(f"wrote {out}")
    else:
        print(text)


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(prog="roof_dial", description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("sweep", help="aperture curve from a bound-book extract")
    p.add_argument("bound_csv")
    p.add_argument("--bars", type=_bars, default=DEFAULT_BARS)
    p.add_argument("--months", type=float, default=None,
                   help="window length in months, for per-month volumes")
    p.add_argument("--segment-by", default="age_band", choices=["age_band", "state"])
    p.add_argument("-o", "--out", default=None)

    p = sub.add_parser("overlay", help="harm overlay from an outcomes extract")
    p.add_argument("outcomes_csv")
    p.add_argument("--bars", type=_bars, default=DEFAULT_BARS)
    p.add_argument("--window", type=int, default=90)
    p.add_argument("-o", "--out", default=None)

    p = sub.add_parser("disposition", help="classify over-applies at one bar")
    p.add_argument("bound_csv")
    p.add_argument("outcomes_csv")
    p.add_argument("--bar", type=float, required=True)
    p.add_argument("--window", type=int, default=90)
    p.add_argument("-o", "--out", default=None)

    sub.add_parser("example", help="zero-setup demo on the 8/20 probe counts")

    args = ap.parse_args(argv)

    if args.cmd == "sweep":
        points = sweep(read_bound_book(args.bound_csv), bars=args.bars,
                       months=args.months, segment_by=args.segment_by)
        _emit(render_sweep(points, months=args.months), args.out)
    elif args.cmd == "overlay":
        points = overlay(read_outcomes(args.outcomes_csv), bars=args.bars,
                         window_days=args.window)
        _emit(render_overlay(points, window_days=args.window), args.out)
    elif args.cmd == "disposition":
        counts = disposition(read_bound_book(args.bound_csv),
                             read_outcomes(args.outcomes_csv),
                             bar=args.bar, window_days=args.window)
        _emit(render_disposition(counts, bar=args.bar, window_days=args.window), args.out)
    elif args.cmd == "example":
        counts = read_banded(str(EXAMPLES / "bound_101plus_bands_20260820.csv"))
        points = sweep_banded(counts, bars=(61, 71, 81, 91), months=3.5,
                              segment="bound 101+ (May 1 to Aug 15 2026, banded preview)")
        print("Preview curve from the 2026-08-20 probe (banded counts; the real")
        print("Phase 1 curve sweeps finer bars from a row-level extract):\n")
        print(render_sweep(points, months=3.5))
    return 0


if __name__ == "__main__":
    sys.exit(main())
