"""Regression specifications for gaps in the roof first read.

Synthetic fixtures only. No customer or policy records. Original modules are
intentionally unchanged; strict expected failures document proposed contracts.
"""
import math
try:
    import pytest
except ModuleNotFoundError:
    import unittest

    raise unittest.SkipTest("Review regression cases require pytest; run uv run --with pytest pytest -q")

from roof_dial.sweep import AUTO, HAND, NONE, DEFAULT_BARS, Dwelling, classify, sweep
from roof_dial.overlay import Outcome, overlay
from roof_dial.report import marginal_steps


@pytest.mark.xfail(strict=True, reason="T1/A6: current signature cannot distinguish a UW apply on a flag-on exclude row")
def test_hand_apply_actor_is_not_overridden_by_model_signature():
    # Ground truth in this fixture: UW applied the coverage after automation did not.
    assert classify(True, "yes", "exclude") == HAND


@pytest.mark.xfail(strict=True, reason="T1/A6: removed auto coverage must retain a removed-auto history category")
def test_prebind_auto_removal_is_not_an_unexposed_negative():
    # Ground truth: automation applied coverage, then it was removed before bind.
    assert classify(False, "yes", "exclude") != NONE


@pytest.mark.xfail(strict=True, reason="T1/A6: a later rescore to pass erases prior auto actor attribution")
def test_rescored_auto_apply_keeps_auto_actor():
    assert classify(True, "yes", "pass") == AUTO


@pytest.mark.xfail(strict=True, reason="T1: empty hand denominator is undefined, not zero capture")
def test_empty_capture_is_not_reported_as_zero():
    point = sweep([Dwelling(NONE, 90)], bars=(83,))[0]
    assert point.catch_pct is None


@pytest.mark.xfail(strict=True, reason="T2: positive over-apply cost with zero additional catches is infinite, not no step")
def test_zero_catch_step_is_distinct_from_top_bar():
    points = sweep([Dwelling(HAND, 95), Dwelling(NONE, 85)], bars=(90, 80))
    steps = marginal_steps(points)
    assert steps[90] is None
    assert math.isinf(steps[80])


@pytest.mark.xfail(strict=True, reason="R4/T2: default candidate grid omits bar 83")
def test_default_grid_includes_candidate_83():
    assert 83 in DEFAULT_BARS


def test_bar_83_preserves_float_boundary_and_unscored_denominator():
    points = sweep([Dwelling(HAND, 83.0), Dwelling(HAND, 82.9),
                    Dwelling(HAND, None), Dwelling(NONE, 83.0),
                    Dwelling(NONE, 82.99), Dwelling(AUTO, 99)], bars=(83,))
    point = points[0]
    assert (point.hand_total, point.hand_unscored, point.catches) == (3, 1, 1)
    assert (point.left_alone_total, point.over_applies) == (2, 1)


@pytest.mark.xfail(strict=True, reason="T4/A19: overlay counts event rows rather than distinct policies per kind/window")
def test_overlay_deduplicates_repeat_transactions_per_policy():
    rows = [Outcome("synthetic_policy", "roof_noe", 10, 85),
            Outcome("synthetic_policy", "roof_noe", 20, 85)]
    point = overlay(rows, bars=(83,), kinds=("roof_noe",))[0]
    assert (point.in_window, point.at_or_above) == (1, 1)


@pytest.mark.xfail(strict=True, reason="T4/A19: overlay lacks an April bind-era filter")
def test_overlay_april_population_excludes_pre_score_era():
    rows = [Outcome("synthetic_january", "roof_noe", 10, None, bind_month="2026-01-01"),
            Outcome("synthetic_april", "roof_noe", 20, 85, bind_month="2026-04-01")]
    point = overlay(rows, bars=(83,), kinds=("roof_noe",))[0]
    assert point.in_window == 1
