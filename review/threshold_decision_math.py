#!/usr/bin/env python3
"""Reproduce aggregate threshold arithmetic without a database connection.

Run from any directory:
    python3 review/threshold_decision_math.py

Writes only review/threshold_decision_math.json. All source inputs are public
aggregate counts. A utility optimum is conditional on the supplied objective,
not a causal estimate or an endorsement of historical workflow labels.
"""

from __future__ import annotations

import json
from dataclasses import dataclass
from fractions import Fraction
from pathlib import Path

HERE = Path(__file__).resolve().parent


@dataclass(frozen=True)
class Point:
    bar: int | str
    hand: int
    none: int


ORIGINAL = [
    Point(95, 227, 102), Point(90, 394, 244), Point(85, 516, 429),
    Point(83, 557, 528), Point(80, 618, 682), Point(75, 707, 927),
    Point(70, 765, 1130), Point(65, 809, 1329), Point(60, 843, 1552),
    Point(55, 881, 1781), Point("no_new_score_rule", 0, 0),
]


def exact(value: Fraction | None) -> dict | None:
    if value is None:
        return None  # Unbounded, never an estimated large finite value.
    return {"fraction": str(value), "decimal": float(value)}


def optimal_intervals(points: list[Point]) -> list[dict]:
    """Solve every pairwise R*H-N inequality, restricted to R >= 0.

    A zero-width interval is a tie at one ratio. A missing interval means the
    point is never best on the supplied candidate grid. Duplicate points share
    the same interval. No rounded or greedy adjacent-step decisions are used.
    """
    answer = []
    for p in points:
        low, high = Fraction(0), None
        low_against, high_against, impossible = [], [], False
        for q in points:
            dh, dn = p.hand - q.hand, p.none - q.none
            if dh == 0:
                impossible |= dn > 0
                continue
            edge = Fraction(dn, dh)
            if dh > 0:
                if edge > low:
                    low, low_against = edge, [q.bar]
                elif edge == low:
                    low_against.append(q.bar)
            else:
                if high is None or edge < high:
                    high, high_against = edge, [q.bar]
                elif edge == high:
                    high_against.append(q.bar)
        feasible = not impossible and (high is None or low <= high)
        answer.append({
            "bar": p.bar, "hand": p.hand, "none": p.none,
            "globally_optimal_for_some_nonnegative_R": feasible,
            "R_low": exact(low), "R_high": exact(high),
            "low_binding_competitors": low_against,
            "high_binding_competitors": high_against,
            "endpoints_are_ties": True,
        })
    return answer


def choose(points: list[Point], ratio: Fraction, u_h=Fraction(0), u_n=Fraction(0)):
    """Coverage-retention surrogate only, excluding prompt/review costs."""
    scored = [(ratio * (1 - u_h) * p.hand - (1 - u_n) * p.none, p)
              for p in points]
    best = max(value for value, _ in scored)
    return {"bars": [p.bar for value, p in scored if value == best],
            "utility_in_C_units": float(best)}


def minimax_regret(points: list[Point], low: Fraction, high: Fraction):
    """Declared interval only. Convex regret achieves its maximum at an end."""
    best_low = max(low * p.hand - p.none for p in points)
    best_high = max(high * p.hand - p.none for p in points)
    rows = [{"bar": p.bar,
             "worst_regret_C_units": max(best_low - (low * p.hand - p.none),
                                         best_high - (high * p.hand - p.none))}
            for p in points]
    best = min(row["worst_regret_C_units"] for row in rows)
    return {"assumed_R_interval": [float(low), float(high)],
            "bars": [row["bar"] for row in rows if row["worst_regret_C_units"] == best],
            "worst_regret_C_units": float(best),
            "all_candidates": [{**r, "worst_regret_C_units": float(r["worst_regret_C_units"])}
                               for r in rows]}


def aggregate_rows(path: Path, name: str) -> list[dict]:
    source = json.loads(path.read_text())
    return [dict(zip(result["cols"], row))
            for result in source["runs"][name] if result.get("status") == "completed"
            for row in result["rows"]]


def coarse_current() -> list[Point]:
    rows = aggregate_rows(HERE / "baseline_runs.json", "baseline_phase1.sql")
    chosen = [r for r in rows if r["window_cut"] == "May 1-August 15"
              and r["version_cut"] == "v1.2.0" and r["state_cut"] == "all"
              and r["age_band"] == "101+"]
    assert len(chosen) == 10, "Do not silently change the historical coarse cohort."
    assert all((r["hand_n"], r["none_n"], r["auto_n"]) == (741, 3125, 44)
               for r in chosen)
    return sorted([Point(r["bar"], r["catches"], r["over_applies"]) for r in chosen],
                  key=lambda p: -int(p.bar)) + [Point("no_new_score_rule", 0, 0)]


def hatch_counts(point: Point, u_h: Fraction, u_n: Fraction, hand_total=741,
                 retained_existing_auto=44, audit_fraction=Fraction(1, 10)):
    """Illustrative home counts, not exposure-years or validated good/bad roofs.

    The audit fraction applies to all accepted attestations. Existing auto is
    preserved and not offered a hatch in this illustration. Historical H/N
    rows are not independent policy reviews, so these are workload triggers.
    """
    removed_h, removed_n = u_h * point.hand, u_n * point.none
    retained_h, retained_n = point.hand - removed_h, point.none - removed_n
    return {"bar": point.bar, "u_hand": float(u_h), "u_none": float(u_n),
            "new_prompt_homes": point.hand + point.none,
            "accepted_removals_hand_signature": float(removed_h),
            "accepted_removals_none_signature": float(removed_n),
            "retained_hand_signature": float(retained_h),
            "retained_none_signature": float(retained_n),
            "historical_hand_without_exclusion_if_age_review_removed": float(hand_total - retained_h),
            "total_excluded_homes_including_existing_auto": float(retained_existing_auto + retained_h + retained_n),
            "audit_triggers_at_assumed_fraction": float(audit_fraction * (removed_h + removed_n)),
            "audit_fraction_assumed": float(audit_fraction)}


def hatch_dominance_bounds(points: list[Point]) -> list[dict]:
    by_bar = {p.bar: p for p in points}
    rows = []
    for lower_bar, higher_bar in [(83, 85), (80, 85), (80, 83)]:
        lower, higher = by_bar[lower_bar], by_bar[higher_bar]
        rows.append({
            "lower_bar_with_hatch": lower_bar, "higher_bar_without_hatch": higher_bar,
            "maximum_hand_signature_removal_for_no_fewer_matches": exact(Fraction(lower.hand - higher.hand, lower.hand)),
            "minimum_none_signature_removal_for_no_more_restrictions": exact(Fraction(lower.none - higher.none, lower.none)),
            "ignores_prompt_audit_and_other_costs": True,
        })
    return rows


def general_utility(class_bands: list[dict], bar: int, common_work_savings=0.0):
    """General dollar objective, for measured or explicitly assumed inputs.

    Each score/class cell supplies: n, score, saved_review_dollars_per_home,
    legitimate_removal_probability, erroneous_removal_probability,
    retained_loss_protection_dollars, retained_customer_cost_dollars,
    legitimate_removal_extra_cost_dollars, erroneous_removal_extra_cost_dollars,
    prompt_cost_dollars, residual_review_probability, residual_review_cost_dollars.

    Cost/loss values must already have common quote-level horizon, bind chance,
    exposure duration and coverage persistence. Error costs exclude protection
    already lost by a removal, avoiding double counting. The H/N workflow proxy
    is not used to assert that a removal is legitimate or erroneous.
    """
    result = {"utility_dollars": common_work_savings, "prompt_homes": 0,
              "accepted_removals": 0.0, "legitimate_removals": 0.0,
              "erroneous_removals": 0.0, "retained_exclusion_homes": 0.0,
              "residual_review_triggers": 0.0}
    for c in class_bands:
        if c["score"] < bar:
            continue
        n = c["n"]
        a_l, a_e = c["legitimate_removal_probability"], c["erroneous_removal_probability"]
        assert 0 <= a_l <= 1 and 0 <= a_e <= 1 and a_l + a_e <= 1
        retained = 1 - a_l - a_e
        value = (c["saved_review_dollars_per_home"]
                 + retained * (c["retained_loss_protection_dollars"] - c["retained_customer_cost_dollars"])
                 - a_l * c["legitimate_removal_extra_cost_dollars"]
                 - a_e * c["erroneous_removal_extra_cost_dollars"]
                 - c["prompt_cost_dollars"]
                 - c["residual_review_probability"] * c["residual_review_cost_dollars"])
        result["utility_dollars"] += n * value
        result["prompt_homes"] += n
        result["accepted_removals"] += n * (a_l + a_e)
        result["legitimate_removals"] += n * a_l
        result["erroneous_removals"] += n * a_e
        result["retained_exclusion_homes"] += n * retained
        result["residual_review_triggers"] += n * c["residual_review_probability"]
    return result


def grid_output(points: list[Point]) -> dict:
    return {"candidate_count": len(points), "intervals": optimal_intervals(points),
            "lower_bar_hatch_vs_higher_bar_no_hatch": hatch_dominance_bounds(points),
            "point_scenarios": [
                {"R_assumed": float(r), "u_H_assumed": float(h), "u_N_assumed": float(n),
                 **choose(points, r, h, n)}
                for r in [Fraction(1), Fraction(3, 2), Fraction(2), Fraction(5, 2), Fraction(27, 10), Fraction(3)]
                for h, n in [(Fraction(0), Fraction(0)), (Fraction(1, 10), Fraction(1, 2)),
                             (Fraction(1, 2), Fraction(1, 2)), (Fraction(1, 2), Fraction(1, 10))]],
            "minimax_illustrations_only": [minimax_regret(points, Fraction(1), Fraction(2)),
                                          minimax_regret(points, Fraction(1), Fraction(3)),
                                          minimax_regret(points, Fraction(3, 2), Fraction(5, 2))]}


def integer_grid_if_available() -> dict:
    """Read the independently queried complete integer grid, when present."""
    path = HERE / "threshold_empirical_runs.json"
    if not path.exists():
        return {"status": "not available when script ran", "groups": []}
    data = json.loads(path.read_text())
    groups = {}
    for statement in data.get("runs", {}).get("threshold_empirical_sweep.sql", []):
        if statement.get("status") != "completed":
            continue
        for row in statement.get("rows", []):
            r = dict(zip(statement["cols"], row))
            if not {"cohort", "population", "bar", "caught_hand_homes", "added_none_homes"} <= r.keys():
                continue
            key = (r["cohort"], r["population"])
            groups.setdefault(key, []).append(r)
    answer = []
    for (cohort, population), rows in sorted(groups.items()):
        points = [Point(r["bar"], r["caught_hand_homes"], r["added_none_homes"]) for r in rows]
        assert len(points) == len({p.bar for p in points}), "Duplicate grid rows need another group key."
        assert {p.bar for p in points} == set(range(102)), "Incomplete integer grid."
        points.append(Point("no_new_score_rule", 0, 0))
        ranked = sorted(rows, key=lambda r: r["bar"])
        capacity = {}
        for grain in ("homes", "quotes"):
            feasible = [r for r in ranked if r[f"selected_{grain}"] / r[grain] <= 0.20]
            capacity[grain] = (None if not feasible else {
                "lowest_bar_at_or_below_20pct": feasible[0]["bar"],
                "selected": feasible[0][f"selected_{grain}"],
                "total": feasible[0][grain],
                "fraction": feasible[0][f"selected_{grain}"] / feasible[0][grain],
                "includes_preserved_current_auto": True,
            })
        answer.append({"cohort": cohort, "population": population,
                       "workflow_labels_are_unvalidated_proxies": True,
                       "capacity_illustration_20pct": capacity,
                       "hatch_count_illustrations": [
                           hatch_counts(p, Fraction(1, 10), Fraction(1, 2),
                                        hand_total=rows[0]["hand_homes"],
                                        retained_existing_auto=rows[0]["auto_homes"])
                           for p in points if p.bar in (80, 83, 85)],
                       **grid_output(points)})
    return {"status": "complete aggregate groups read" if answer else "no completed matching rows", "groups": answer}


def literal_recent_proxy_if_available() -> dict:
    """Optimize actual aggregate retained signatures, not a uniform hatch rate.

    This is the literal vendor-year counterfactual, not actual attestations or
    proof of full roof replacement. It preserves unknown-year restrictions.
    """
    path = HERE / "threshold_escape_runs.json"
    if not path.exists():
        return {"status": "not available when script ran", "groups": []}
    data = json.loads(path.read_text())
    groups = {}
    for statement in data.get("new_database_executions", []):
        if statement.get("check") != "threshold_escape_frontier" or statement.get("status") != "completed":
            continue
        for raw in statement["rows"]:
            row = dict(zip(statement["columns"], raw))
            groups.setdefault(row["population"], []).append(row)
    answer = []
    for population, rows in sorted(groups.items()):
        points = [Point(r["bar"], r["retained_H_literal_recent_proxy"],
                        r["retained_N_literal_recent_proxy"]) for r in rows]
        assert len(points) == len({p.bar for p in points})
        assert {p.bar for p in points} == set(range(102)), "Incomplete recorded-year grid."
        points.append(Point("no_new_score_rule", 0, 0))
        answer.append({
            "population": population, "homes": rows[0]["homes"],
            "all_H": rows[0]["all_H"], "all_N": rows[0]["all_N"],
            "all_auto": rows[0]["all_auto"],
            "existing_auto_recent_proxy": rows[0]["existing_auto_recent_proxy"],
            "intervals": optimal_intervals(points),
            "point_scenarios_without_any_further_hatch": [
                {"R_assumed": float(r), **choose(points, r)}
                for r in [Fraction(1), Fraction(3, 2), Fraction(2), Fraction(5, 2), Fraction(27, 10), Fraction(3)]],
            "minimax_illustrations_only": [minimax_regret(points, Fraction(1), Fraction(2)),
                                          minimax_regret(points, Fraction(1), Fraction(3)),
                                          minimax_regret(points, Fraction(3, 2), Fraction(5, 2))],
            "selected_comparisons": [r for r in rows if r["bar"] in [80, 81, 82, 83, 84, 85, 87, 88]],
        })
    return {"status": "complete aggregate groups read" if answer else "no completed matching rows",
            "interpretation": "Remove all selected CAPE roof-year 2007-2026 proxy; keep unknown/boundary. Not measured uptake.",
            "groups": answer}


def main():
    current = coarse_current()
    output = {
        "generated_from_local_aggregates_only": True,
        "date": "2026-09-23", "scope": "First-read threshold decision arithmetic; all utility inputs are conditional.",
        "original_coarse": grid_output(ORIGINAL),
        "current_v1_2_coarse": grid_output(current),
        "hatch_count_illustrations_current_v1_2_bound": [
            hatch_counts(p, h, n) for p in current if p.bar in (80, 83, 85)
            for h, n in [(Fraction(0), Fraction(0)), (Fraction(1, 10), Fraction(1, 2)),
                         (Fraction(1, 2), Fraction(1, 2)), (Fraction(1, 2), Fraction(1, 10))]],
        "p80_reproduction": aggregate_rows(HERE / "baseline_runs.json", "baseline_p80_proxy.sql"),
        "integer_grid": integer_grid_if_available(),
        "literal_recent_roof_proxy": literal_recent_proxy_if_available(),
    }
    # Internal arithmetic invariants check the optimizer, not the source data.
    original = {p["bar"]: p for p in output["original_coarse"]["intervals"]}
    assert original[83]["R_low"]["fraction"] == "99/41"
    assert original[83]["R_high"]["fraction"] == "154/61"
    assert not original[60]["globally_optimal_for_some_nonnegative_R"]
    assert choose(ORIGINAL, Fraction(251, 100))["bars"] == [83]
    assert choose(ORIGINAL, Fraction(63, 10))["bars"] == [55]
    assert (choose(current, Fraction(2), Fraction(1, 2), Fraction(1, 2))["bars"]
            == choose(current, Fraction(2))["bars"])
    path = HERE / "threshold_decision_math.json"
    path.write_text(json.dumps(output, indent=2) + "\n")
    print(f"Wrote {path.name}; all calculations use public aggregate inputs.")
    for name in ("original_coarse", "current_v1_2_coarse"):
        print(name)
        for row in output[name]["intervals"]:
            if row["bar"] in (80, 83, 85):
                print(row["bar"], row["R_low"], row["R_high"])


if __name__ == "__main__":
    main()
