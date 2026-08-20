import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

from roof_dial.sweep import (  # noqa: E402
    AUTO, HAND, NONE, Dwelling, classify, read_banded, sweep, sweep_banded,
)

EXAMPLES = pathlib.Path(__file__).resolve().parents[1] / "examples"


class TestClassify(unittest.TestCase):
    def test_auto_needs_flag_and_decision(self):
        self.assertEqual(classify(True, "yes", "exclude"), AUTO)
        self.assertEqual(classify(True, "yes", "pass"), HAND)
        self.assertEqual(classify(True, "no", "exclude"), HAND)
        self.assertEqual(classify(True, "", ""), HAND)
        self.assertEqual(classify(False, "yes", "exclude"), NONE)


class TestSweepRowLevel(unittest.TestCase):
    def setUp(self):
        self.rows = [
            Dwelling(HAND, 90.0), Dwelling(HAND, 70.0), Dwelling(HAND, None),
            Dwelling(NONE, 95.0), Dwelling(NONE, 50.0),
            Dwelling(AUTO, 99.0),  # must not enter either denominator
        ]

    def test_bar_80(self):
        (pt,) = [p for p in sweep(self.rows, bars=(80,)) if p.segment == "ALL"]
        self.assertEqual(pt.hand_total, 3)          # unscored stays in
        self.assertEqual(pt.hand_unscored, 1)
        self.assertEqual(pt.catches, 1)
        self.assertAlmostEqual(pt.catch_pct, 100.0 / 3, places=4)
        self.assertEqual(pt.left_alone_total, 2)
        self.assertEqual(pt.over_applies, 1)
        self.assertAlmostEqual(pt.over_share_pct, 50.0, places=4)
        self.assertAlmostEqual(pt.over_per_catch, 1.0, places=4)

    def test_months_volumes(self):
        (pt,) = [p for p in sweep(self.rows, bars=(80,), months=2.0) if p.segment == "ALL"]
        self.assertAlmostEqual(pt.catches_per_month, 0.5, places=4)
        self.assertAlmostEqual(pt.over_per_month, 0.5, places=4)


class TestBandedReproducesProbe(unittest.TestCase):
    """The 2026-08-20 probe numbers (bound 101+ book, May 1 to Aug 15) are
    pinned here: 1,018 hand-applied (8 unscored) and 4,404 left alone."""

    @classmethod
    def setUpClass(cls):
        counts = read_banded(str(EXAMPLES / "bound_101plus_bands_20260820.csv"))
        cls.by_bar = {p.bar: p for p in sweep_banded(counts, bars=(61, 71, 81, 91))}

    def test_denominators(self):
        pt = self.by_bar[91]
        self.assertEqual(pt.hand_total, 1018)
        self.assertEqual(pt.hand_unscored, 8)
        self.assertEqual(pt.left_alone_total, 4404)

    def test_bar_91(self):
        pt = self.by_bar[91]
        self.assertEqual((pt.catches, pt.over_applies), (367, 214))
        self.assertAlmostEqual(pt.catch_pct, 36.05, places=1)
        self.assertAlmostEqual(pt.over_share_pct, 4.86, places=1)
        self.assertAlmostEqual(pt.over_per_catch, 0.58, places=2)

    def test_bar_81(self):
        pt = self.by_bar[81]
        self.assertEqual((pt.catches, pt.over_applies), (599, 632))
        self.assertAlmostEqual(pt.catch_pct, 58.84, places=1)
        self.assertAlmostEqual(pt.over_share_pct, 14.35, places=1)
        self.assertAlmostEqual(pt.over_per_catch, 1.06, places=2)

    def test_bar_71(self):
        pt = self.by_bar[71]
        self.assertEqual((pt.catches, pt.over_applies), (758, 1076))
        self.assertAlmostEqual(pt.catch_pct, 74.46, places=1)
        self.assertAlmostEqual(pt.over_share_pct, 24.43, places=1)

    def test_bar_61(self):
        pt = self.by_bar[61]
        self.assertEqual((pt.catches, pt.over_applies), (838, 1524))
        self.assertAlmostEqual(pt.catch_pct, 82.32, places=1)
        self.assertAlmostEqual(pt.over_share_pct, 34.60, places=1)

    def test_off_floor_bar_rejected(self):
        counts = read_banded(str(EXAMPLES / "bound_101plus_bands_20260820.csv"))
        with self.assertRaises(ValueError):
            sweep_banded(counts, bars=(75,))


if __name__ == "__main__":
    unittest.main()
