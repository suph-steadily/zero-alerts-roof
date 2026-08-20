import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

from roof_dial.overlay import Outcome, disposition, overlay  # noqa: E402
from roof_dial.sweep import HAND, NONE, Dwelling  # noqa: E402


class TestOverlay(unittest.TestCase):
    def setUp(self):
        self.outcomes = [
            Outcome("A", "roof_noe", 10, 85.0),
            Outcome("B", "roof_noe", 95, 90.0),   # outside the 90-day window
            Outcome("C", "roof_noe", 20, None),   # no bind-time score (pre-April bind)
            Outcome("D", "roof_noc", 30, 70.0),
        ]

    def test_window_and_denominators(self):
        pts = {(p.kind, p.bar): p for p in overlay(self.outcomes, bars=(80,))}
        noe = pts[("roof_noe", 80)]
        self.assertEqual(noe.in_window, 2)       # A and C; B is out of window
        self.assertEqual(noe.scored, 1)          # only A has a score
        self.assertEqual(noe.at_or_above, 1)
        self.assertAlmostEqual(noe.pct_of_in_window, 50.0, places=4)
        self.assertAlmostEqual(noe.pct_of_scored, 100.0, places=4)
        noc = pts[("roof_noc", 80)]
        self.assertEqual((noc.in_window, noc.scored, noc.at_or_above), (1, 1, 0))


class TestDisposition(unittest.TestCase):
    def test_three_classes(self):
        dwellings = [
            Dwelling(NONE, 85.0, policy_id="A", uw_reviewed=False),  # harmed later
            Dwelling(NONE, 90.0, policy_id="B", uw_reviewed=True),   # UW said leave it
            Dwelling(NONE, 82.0, policy_id="C", uw_reviewed=False),  # clean
            Dwelling(NONE, 70.0, policy_id="D", uw_reviewed=False),  # below the bar
            Dwelling(HAND, 95.0, policy_id="E"),                     # not an over-apply
        ]
        outcomes = [Outcome("A", "roof_noc", 40, 85.0)]
        got = disposition(dwellings, outcomes, bar=80)
        self.assertEqual(got, {
            "late_catch": 1,
            "true_disagreement": 1,
            "presumed_false_positive": 1,
        })


if __name__ == "__main__":
    unittest.main()
