"""Aperture sweep: replay candidate score bars over the bound book.

Input rows come from ``sql/01_bound_book.sql`` (one CSV row per bound
new-business dwelling). Each dwelling lands in one of three groups:

  * auto: the exclusion is on the quote and the automation put it there
          (flag 'yes' and the model decision 'exclude')
  * hand: the exclusion is on the quote and the automation did not put it there
          (an underwriter did; agents cannot set this coverage)
  * none: no roof surfacing exclusion on the quote (left alone)

At each candidate bar T (score runs 1 to 100, higher is worse):

  * catch      = a hand dwelling scoring at or above T
  * catch pct  = catches per 100 hand dwellings; unscored hand dwellings
                 STAY IN the denominator and are reported separately,
                 so a bar is never credited for roofs it cannot see
  * over-apply = a none dwelling scoring at or above T

Stdlib only, same house rules as the weighing machine: every rate names
its denominator, nothing is dropped silently.
"""

from __future__ import annotations

import csv
from dataclasses import dataclass
from typing import Dict, List, Optional, Sequence

AUTO = "auto"
HAND = "hand"
NONE = "none"

DEFAULT_BARS: Sequence[float] = tuple(range(55, 100, 5))  # 55, 60, ... 95

# Score bands as they come out of the probe queries; floors let a banded
# count table answer bars that sit exactly on a band edge.
BAND_FLOORS = {"<=50": 0, "51-60": 51, "61-70": 61, "71-80": 71, "81-90": 81, "91-100": 91}
UNSCORED_BAND = "null"


@dataclass(frozen=True)
class Dwelling:
    group: str                    # auto / hand / none
    score: Optional[float]        # None = the model produced no score
    age_band: str = "ALL"
    state: str = ""
    policy_id: str = ""
    uw_reviewed: bool = False


@dataclass(frozen=True)
class SweepPoint:
    segment: str                  # 'ALL' or an age band / state value
    bar: float
    hand_total: int               # denominator: ALL hand-applied dwellings
    hand_unscored: int
    catches: int
    catch_pct: float              # per 100 hand-applied (unscored included)
    left_alone_total: int         # denominator: ALL left-alone dwellings
    over_applies: int
    over_share_pct: float         # per 100 left-alone
    over_per_catch: Optional[float]
    catches_per_month: Optional[float]
    over_per_month: Optional[float]


def classify(rse_selected: bool, flag: str, decision: str) -> str:
    """Who put the exclusion on the quote (or nobody)."""
    if not rse_selected:
        return NONE
    if flag == "yes" and decision == "exclude":
        return AUTO
    return HAND


def _parse_score(raw: str) -> Optional[float]:
    raw = (raw or "").strip()
    if raw == "" or raw.lower() in ("null", "none", "\\n"):
        return None
    return float(raw)


def read_bound_book(path: str) -> List[Dwelling]:
    """Read the CSV produced by sql/01_bound_book.sql."""
    out: List[Dwelling] = []
    with open(path, newline="") as fh:
        for row in csv.DictReader(fh):
            rse = str(row.get("rse_selected", "0")).strip() in ("1", "true", "True", "yes")
            reviewed = str(row.get("uw_reviewed", "0")).strip() in ("1", "true", "True", "yes")
            out.append(
                Dwelling(
                    group=classify(rse, (row.get("flag") or "").strip(),
                                   (row.get("decision") or "").strip()),
                    score=_parse_score(row.get("score", "")),
                    age_band=(row.get("age_band") or "ALL").strip(),
                    state=(row.get("state") or "").strip(),
                    policy_id=(row.get("policy_id") or "").strip(),
                    uw_reviewed=reviewed,
                )
            )
    return out


def _point(segment: str, bar: float, hand: List[Optional[float]],
           none: List[Optional[float]], months: Optional[float]) -> SweepPoint:
    hand_total = len(hand)
    hand_unscored = sum(1 for s in hand if s is None)
    catches = sum(1 for s in hand if s is not None and s >= bar)
    left_total = len(none)
    over = sum(1 for s in none if s is not None and s >= bar)
    return SweepPoint(
        segment=segment,
        bar=bar,
        hand_total=hand_total,
        hand_unscored=hand_unscored,
        catches=catches,
        catch_pct=100.0 * catches / hand_total if hand_total else 0.0,
        left_alone_total=left_total,
        over_applies=over,
        over_share_pct=100.0 * over / left_total if left_total else 0.0,
        over_per_catch=(over / catches) if catches else None,
        catches_per_month=(catches / months) if months else None,
        over_per_month=(over / months) if months else None,
    )


def sweep(dwellings: Sequence[Dwelling], bars: Sequence[float] = DEFAULT_BARS,
          months: Optional[float] = None, segment_by: str = "age_band") -> List[SweepPoint]:
    """The curve: one SweepPoint per (segment, bar), 'ALL' rollup first."""
    segments: Dict[str, Dict[str, List[Optional[float]]]] = {"ALL": {HAND: [], NONE: []}}
    for d in dwellings:
        if d.group == AUTO:
            continue  # already automated; not part of either denominator
        key = getattr(d, segment_by, "ALL") or "ALL"
        segments.setdefault(key, {HAND: [], NONE: []})
        for seg in ("ALL",) if key == "ALL" else ("ALL", key):
            segments[seg][d.group].append(d.score)
    points: List[SweepPoint] = []
    for seg in sorted(segments, key=lambda s: (s != "ALL", s)):
        for bar in bars:
            points.append(_point(seg, bar, segments[seg][HAND], segments[seg][NONE], months))
    return points


def read_banded(path: str) -> Dict[str, Dict[str, int]]:
    """Read a banded count table (group, score_band, count) like examples/."""
    counts: Dict[str, Dict[str, int]] = {}
    with open(path, newline="") as fh:
        for row in csv.DictReader(fh):
            grp = row["group"].strip()
            counts.setdefault(grp, {})[row["score_band"].strip()] = int(row["count"])
    return counts


def sweep_banded(counts: Dict[str, Dict[str, int]], bars: Sequence[float] = (61, 71, 81, 91),
                 months: Optional[float] = None, segment: str = "ALL") -> List[SweepPoint]:
    """Same math from banded counts. Bars must sit on band floors (51/61/71/81/91)."""
    floors = sorted(BAND_FLOORS.values())

    def expand(grp: str) -> List[Optional[float]]:
        scores: List[Optional[float]] = []
        for band, n in counts.get(grp, {}).items():
            if band == UNSCORED_BAND:
                scores.extend([None] * n)
            else:
                scores.extend([float(BAND_FLOORS[band])] * n)
        return scores

    for bar in bars:
        if bar not in floors:
            raise ValueError(f"banded sweep only supports bars on band floors {floors}, got {bar}")
    hand, none = expand(HAND), expand(NONE)
    return [_point(segment, bar, hand, none, months) for bar in bars]
