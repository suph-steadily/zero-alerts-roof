"""Harm overlay and over-apply disposition.

The overlay answers: of the post-bind roof harms that actually happened,
how many had a bind-time score at or above each candidate bar (so a wider
bar would have handled them before bind)?

Input rows come from ``sql/02_postbind_roof_outcomes.sql``: one row per
post-bind event with the policy's bind-time score joined on.

  * kind 'roof_noe'    = an underwriter added the roof surfacing exclusion
                         after bind (the corrective endorsement lane)
  * kind 'roof_noc'    = inspection cancellation, sub-reason Condition - Roof
  * kind 'rse_removed' = the exclusion came OFF after bind (pushback lane)

Era honesty: bind-time scores exist on April 2026+ binds only, so shares
are reported against two named denominators (all events in window, and
scored events in window). Quote the scored-denominator share only next to
its coverage.

The disposition classifies over-applies at ONE bar:
  late_catch               that home drew a roof NOE or NOC in-window anyway
  true_disagreement        an underwriter reviewed the quote, left the roof alone
  presumed_false_positive (WITHDRAWN 8/21: no outcome-eligibility state, see report banner)  never reviewed, clean in the window
"""

from __future__ import annotations

import csv
from dataclasses import dataclass
from typing import Dict, List, Optional, Sequence, Set

from .sweep import Dwelling, NONE, _parse_score

KINDS = ("roof_noe", "roof_noc", "rse_removed")


@dataclass(frozen=True)
class Outcome:
    policy_id: str
    kind: str
    days_since_bind: int
    bind_score: Optional[float]
    actor_class: str = ""
    cohort: str = ""
    bind_month: str = ""


@dataclass(frozen=True)
class OverlayPoint:
    kind: str
    bar: float
    in_window: int                # denominator 1: all events of this kind in window
    scored: int                   # denominator 2: those with a bind-time score
    at_or_above: int
    pct_of_in_window: float
    pct_of_scored: float


def read_outcomes(path: str) -> List[Outcome]:
    out: List[Outcome] = []
    with open(path, newline="") as fh:
        for row in csv.DictReader(fh):
            out.append(
                Outcome(
                    policy_id=(row.get("policy_id") or "").strip(),
                    kind=(row.get("kind") or "").strip(),
                    days_since_bind=int(float(row.get("days_since_bind") or 0)),
                    bind_score=_parse_score(row.get("bind_score", "")),
                    actor_class=(row.get("actor_class") or "").strip(),
                    cohort=(row.get("cohort") or "").strip(),
                    bind_month=(row.get("bind_month") or "").strip(),
                )
            )
    return out


def overlay(outcomes: Sequence[Outcome], bars: Sequence[float],
            window_days: int = 90, kinds: Sequence[str] = ("roof_noe", "roof_noc")) -> List[OverlayPoint]:
    points: List[OverlayPoint] = []
    for kind in kinds:
        window = [o for o in outcomes if o.kind == kind and 0 <= o.days_since_bind <= window_days]
        scored = [o for o in window if o.bind_score is not None]
        for bar in bars:
            hit = sum(1 for o in scored if o.bind_score >= bar)
            points.append(
                OverlayPoint(
                    kind=kind,
                    bar=bar,
                    in_window=len(window),
                    scored=len(scored),
                    at_or_above=hit,
                    pct_of_in_window=100.0 * hit / len(window) if window else 0.0,
                    pct_of_scored=100.0 * hit / len(scored) if scored else 0.0,
                )
            )
    return points


def disposition(dwellings: Sequence[Dwelling], outcomes: Sequence[Outcome],
                bar: float, window_days: int = 90) -> Dict[str, int]:
    """Classify each over-apply (left-alone dwelling scoring >= bar) at one bar.

    Works at dwelling grain; 'late catch' means the dwelling's POLICY drew a
    roof NOE or roof NOC inside the window (outcomes are per policy).
    """
    harmed: Set[str] = {
        o.policy_id for o in outcomes
        if o.kind in ("roof_noe", "roof_noc") and 0 <= o.days_since_bind <= window_days
    }
    result = {"late_catch": 0, "true_disagreement": 0, "presumed_false_positive": 0}
    for d in dwellings:
        if d.group != NONE or d.score is None or d.score < bar:
            continue
        if d.policy_id and d.policy_id in harmed:
            result["late_catch"] += 1
        elif d.uw_reviewed:
            result["true_disagreement"] += 1
        else:
            result["presumed_false_positive"] += 1
    return result
