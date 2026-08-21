"""Plain markdown tables for the sweep, the overlay, and the disposition.

Denominators are printed in the header of every table, not hidden in
footnotes; unscored counts always show.
"""

from __future__ import annotations

from typing import Dict, List, Optional

from .overlay import OverlayPoint
from .sweep import SweepPoint


def _fmt(x: Optional[float], nd: int = 1) -> str:
    if x is None:
        return "-"
    return f"{x:,.{nd}f}" if nd else f"{x:,.0f}"


def marginal_steps(points: List[SweepPoint]) -> Dict[float, Optional[float]]:
    """Over-applies per EXTRA catch for the step down onto each bar.

    The running ``over_per_catch`` on a SweepPoint is a cumulative average over
    everything at or above the bar. It is not the cost of moving the bar, and
    reading it as such is what made the 8/20 memo claim a knee at 80-85 that
    the marginal curve does not show. Keyed by bar; the highest bar in the set
    has no step onto it and maps to None.
    """
    ordered = sorted(points, key=lambda p: -p.bar)
    out: Dict[float, Optional[float]] = {ordered[0].bar: None} if ordered else {}
    for higher, lower in zip(ordered, ordered[1:]):
        d_catch = lower.catches - higher.catches
        d_over = lower.over_applies - higher.over_applies
        out[lower.bar] = (d_over / d_catch) if d_catch else None
    return out


def render_sweep(points: List[SweepPoint], months: Optional[float] = None) -> str:
    lines: List[str] = []
    segments = sorted({p.segment for p in points}, key=lambda s: (s != "ALL", s))
    for seg in segments:
        seg_pts = [p for p in points if p.segment == seg]
        first = seg_pts[0]
        lines.append(
            f"### Segment {seg} "
            f"(hand-applied {first.hand_total:,}, of which unscored {first.hand_unscored:,}; "
            f"left alone {first.left_alone_total:,}"
            + (f"; window {months} months)" if months else ")")
        )
        steps = marginal_steps(seg_pts)
        header = ("| bar | captures | capture % of hand-applies | over-applies "
                  "| % of left-alone | running over per catch | over per EXTRA catch (step onto this bar) |")
        divider = "|---|---|---|---|---|---|---|"
        if months:
            header += " catches/mo | over/mo |"
            divider += "---|---|"
        lines.append(header)
        lines.append(divider)
        for p in seg_pts:
            row = (
                f"| {p.bar:g}+ | {p.catches:,} | {_fmt(p.catch_pct)}% "
                f"| {p.over_applies:,} | {_fmt(p.over_share_pct)}% | {_fmt(p.over_per_catch, 2)} "
                f"| {_fmt(steps.get(p.bar), 2)} |"
            )
            if months:
                row += f" {_fmt(p.catches_per_month)} | {_fmt(p.over_per_month)} |"
            lines.append(row)
        lines.append("")
        lines.append(
            "Read the last column, not the one before it, when choosing a bar: the running "
            "average is the cost of every catch at or above the bar, while the step cost is "
            "what the next move down actually buys and pays. Neither picks a bar on its own - "
            "that needs a value for one caught home against one unwanted exclusion."
        )
        lines.append("")
    return "\n".join(lines)


def render_overlay(points: List[OverlayPoint], window_days: int = 90) -> str:
    lines: List[str] = []
    kinds = sorted({p.kind for p in points})
    for kind in kinds:
        kind_pts = [p for p in points if p.kind == kind]
        first = kind_pts[0]
        label = {"roof_noe": "roof NOEs (UW added the exclusion after bind)",
                 "roof_noc": "Condition - Roof NOCs",
                 "rse_removed": "exclusion removals (pushback)"}.get(kind, kind)
        lines.append(
            f"### {label} — {first.in_window:,} in the 0-{window_days} day window, "
            f"{first.scored:,} with a bind-time score"
        )
        lines.append("| bar | would have been at/above the bar | % of all in window | % of scored |")
        lines.append("|---|---|---|---|")
        for p in kind_pts:
            lines.append(
                f"| {p.bar:g}+ | {p.at_or_above:,} | {_fmt(p.pct_of_in_window)}% | {_fmt(p.pct_of_scored)}% |"
            )
        lines.append("")
    return "\n".join(lines)


def render_disposition(counts: Dict[str, int], bar: float, window_days: int = 90) -> str:
    total = sum(counts.values())
    lines = [
        "> **WITHDRAWN 2026-08-21 - do not quote these shares.** There is no "
        "outcome-observation eligibility state here, so any dwelling outside the frozen "
        "outcome census, and any dwelling still inside its 90-day runway, is counted as "
        "clean and falls into `presumed false positive`. The class needs a manifest of "
        "which dwellings could have been observed, and a maturity cut, before it means "
        "anything. See the Corrections section of RESULTS-2026-08-20.md.",
        "",
        f"### Over-applies at bar {bar:g}+ classified over the 0-{window_days} day window "
        f"(total {total:,})",
        "| class | dwellings | share |",
        "|---|---|---|",
    ]
    labels = {
        "late_catch": "late catch (drew a roof NOE or NOC anyway)",
        "true_disagreement": "true disagreement (UW reviewed, left it alone)",
        "presumed_false_positive": "presumed false positive (never reviewed, NOT OBSERVED to be clean)",
    }
    for key in ("late_catch", "true_disagreement", "presumed_false_positive"):
        n = counts.get(key, 0)
        share = 100.0 * n / total if total else 0.0
        lines.append(f"| {labels[key]} | {n:,} | {_fmt(share)}% |")
    lines.append("")
    return "\n".join(lines)
