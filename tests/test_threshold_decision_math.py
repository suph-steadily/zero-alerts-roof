"""Independent synthetic checks of the threshold decision arithmetic."""

import random
import unittest
from fractions import Fraction

from review.threshold_decision_math import (
    Point, choose, general_utility, minimax_regret, optimal_intervals,
)


class DecisionMathTests(unittest.TestCase):
    def test_global_search_skips_a_never_best_middle_candidate(self):
        points = [Point(101, 0, 0), Point(90, 1, 4), Point(80, 2, 5)]
        intervals = {r["bar"]: r for r in optimal_intervals(points)}
        self.assertFalse(intervals[90]["globally_optimal_for_some_nonnegative_R"])
        self.assertEqual(choose(points, Fraction(3))["bars"], [80])
        self.assertEqual(choose(points, Fraction(5, 2))["bars"], [101, 80])

    def test_equal_catches_cannot_justify_more_cost_but_duplicates_tie(self):
        points = [Point(85, 3, 2), Point(84, 3, 2), Point(83, 3, 4)]
        intervals = {r["bar"]: r for r in optimal_intervals(points)}
        self.assertTrue(intervals[85]["globally_optimal_for_some_nonnegative_R"])
        self.assertTrue(intervals[84]["globally_optimal_for_some_nonnegative_R"])
        self.assertFalse(intervals[83]["globally_optimal_for_some_nonnegative_R"])
        self.assertEqual(choose(points, Fraction(0))["bars"], [85, 84])

    def test_intervals_match_direct_utility_on_unsorted_synthetic_curves(self):
        rng = random.Random(83085)
        for _ in range(50):
            points = [Point(i, rng.randrange(12), rng.randrange(15)) for i in range(8)]
            points.append(Point("current", 0, 0))
            intervals = optimal_intervals(points)
            for numerator in range(41):
                ratio = Fraction(numerator, 4)
                predicted = set()
                for row in intervals:
                    if not row["globally_optimal_for_some_nonnegative_R"]:
                        continue
                    lower = Fraction(row["R_low"]["fraction"])
                    upper = row["R_high"]
                    if ratio >= lower and (upper is None or ratio <= Fraction(upper["fraction"])):
                        predicted.add(row["bar"])
                direct = {p.bar for p in points if ratio * p.hand - p.none
                          == max(ratio * q.hand - q.none for q in points)}
                self.assertEqual(predicted, direct)

    def test_equal_hatch_rates_preserve_ranking_selective_rates_change_it(self):
        points = [Point(101, 0, 0), Point(85, 5, 2), Point(80, 8, 7)]
        self.assertEqual(choose(points, Fraction(1))["bars"], [85])
        for rate in [Fraction(0), Fraction(1, 2), Fraction(9, 10)]:
            self.assertEqual(choose(points, Fraction(1), rate, rate)["bars"], [85])
        self.assertEqual(choose(points, Fraction(1), Fraction(0), Fraction(1, 2))["bars"], [80])
        self.assertEqual(choose(points, Fraction(1), Fraction(9, 10), Fraction(0))["bars"], [101])

    def test_regret_endpoints_bound_interior_ratios(self):
        points = [Point(101, 0, 0), Point(85, 5, 2), Point(80, 8, 7)]
        result = minimax_regret(points, Fraction(1), Fraction(3))
        bounds = {r["bar"]: r["worst_regret_C_units"] for r in result["all_candidates"]}
        for numerator in range(10, 31):
            ratio = Fraction(numerator, 10)
            best = max(ratio * p.hand - p.none for p in points)
            for point in points:
                self.assertLessEqual(float(best - (ratio * point.hand - point.none)), bounds[point.bar])

    def test_general_objective_retention_error_prompt_and_common_work(self):
        cell = dict(n=10, score=83, saved_review_dollars_per_home=2,
                    legitimate_removal_probability=.3, erroneous_removal_probability=.2,
                    retained_loss_protection_dollars=20, retained_customer_cost_dollars=3,
                    legitimate_removal_extra_cost_dollars=1, erroneous_removal_extra_cost_dollars=4,
                    prompt_cost_dollars=1, residual_review_probability=.1,
                    residual_review_cost_dollars=5)
        at83 = general_utility([cell], 83, common_work_savings=100)
        self.assertAlmostEqual(at83["utility_dollars"], 179)
        self.assertAlmostEqual(at83["retained_exclusion_homes"], 5)
        self.assertEqual(at83["accepted_removals"], 5)
        self.assertEqual(at83["erroneous_removals"], 2)
        self.assertEqual(at83["residual_review_triggers"], 1)
        at84 = general_utility([cell], 84, common_work_savings=100)
        self.assertEqual(at84["utility_dollars"], 100)
        # Savings shared by all bars cannot change the utility difference.
        no_common = general_utility([cell], 83)
        self.assertAlmostEqual(at83["utility_dollars"] - at84["utility_dollars"],
                               no_common["utility_dollars"])


if __name__ == "__main__":
    unittest.main()
