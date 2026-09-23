# Choosing the roof bar: first read

**My recommendation is 83 as the balanced starting setting for the old-home proposal, with the roof-replacement escape hatch.** The new analysis checks every integer threshold. It gives 83 a concrete mathematical justification under stated cost assumptions, rather than relying on the old “worst 20%” explanation. It does not estimate a profit-maximizing production threshold.

The recommendation uses a declared working assumption: retaining a useful exclusion is worth between one and two times the net cost of an additional persistent restriction, after accounting for the hatch. This is an analyst-selected range, not a measured dollar value or a preference already supplied by underwriting. On the recent bound-home proxy, 83 minimizes the worst missed value across that range. Different priorities give different numbers, shown below.

## What happened to 83

The original analysis reported 83 as the 80th percentile on its mixed-model, bound old-home sample. A current comparable pooled-book rerun still returns 83; the original August snapshot is not preserved for exact reconstruction. That calculation answered “where does roughly the worst fifth of this sample start?” It did not optimize the value of exclusions, customer cost, or the escape hatch.

We have now rerun **all 102 integer cutoffs, 0 through 101**, with model v1.2.0 only. The primary comparison uses July 30-August 31, 2026 new-business creations, homes aged 101+, excluding CO, RI and WV, with Chicago date boundaries. There are 12,577 quote-homes on 10,993 quotes, including 1,597 homes on 1,427 quotes observed issued before September 23.

The recent bound subset contains 295 inferred manual exclusions, 1,287 homes without the exclusion, and 15 existing automatic exclusions. The existing automatic exclusions are preserved at every bar.

| Bar | Historical manual exclusions matched, before hatch | Extra restrictions on previously unrestricted bound homes | All quote-homes selected, before hatch |
|---:|---:|---:|---:|
| 85 | 134 / 295 = 45.4% | 97 | 20.6% |
| **83** | **162 / 295 = 54.9%** | **125** | **23.4%** |
| 80 | 186 / 295 = 63.1% | 175 | 27.3% |
| 66 | 241 / 295 = 81.7% | 334 | 42.7% |

The third and fourth columns use different populations deliberately: bound homes supply the historical coverage comparison; all quotes supply a current-row upper bound on candidate prompt volume, before form eligibility and final prompt rules. Unbound homes without an exclusion have not necessarily been reviewed and approved by an underwriter.

In this recent bound sample, **85 to 83 adds 28 historical manual matches and 28 extra restrictions. Going from 83 to 80 adds another 24 matches and 50 extra restrictions.** These are counts, not dollars, prevented losses, or saved reviews. The older May-August comparison remains 38/56 and 52/100; changing the cohort changes the observed tradeoff.

## The math that makes 83 a reasonable choice

For each bar, count useful coverage retained after the hatch and subtract the cost of extra restrictions that remain. A simple version values each historical manual match at R times the net cost of restricting a previously unrestricted home. With uniform hatch rates within those two groups, the relevant ratio is:

`effective R = value / cost × fraction of manual matches retained / fraction of extra restrictions retained`

On the **recent bound-home curve**, comparing every integer bar, **83 is best when effective R is between 56/43 and 21/11, or approximately 1.30 and 1.91**. The endpoints are ties. If the reasonable range is instead assumed to be 1 through 2, 83 also minimizes the worst missed value across that range. This is the basis for the starting recommendation.

That result improves on the earlier sparse comparison of 80, 83 and 85. In this full integer comparison, 85 is never the best choice under the simple constant-value objective. This does not mean 85 is always a bad business choice; different operating constraints or costs by score can change the ranking.

| Assumed effective value-to-cost ratio | Best bar on the recent bound-home point estimates |
|---:|---|
| 1.0 | 88 |
| 1.5 | **83** |
| 2.0 | 81 or 82, tied |
| 2.7 | 80 |
| 3.0 | 66 |

These are conditional answers, not measured economic prices. Historical manual exclusions are inferred from current records, not verified roof-condition labels. The older May-August bound cohort gives a narrower 83-optimal range, 1.58-1.70; cohort choice and sampling variation matter.

In 2,000 policy-cluster resamples of the recent bound subset, comparing all 102 cutoffs at assumed effective R = 1.5, 83 wins 911 times (45.55%). That is a stability check on this sample and objective, not a 45.55% probability that 83 is the true business optimum. The recommendation is a starting decision under uncertainty, not proof that a neighboring score could never be better.

## The escape hatch is part of the decision

The user's central point is correct: **an exclusion that can be removed should not automatically be charged the same lasting cost as one that stays on the policy.** The calculation must use the restrictions remaining after the agent answers the full-roof-replacement question.

It also needs to count useful exclusions removed by the hatch. Equal removal percentages in both groups leave the relative tradeoff unchanged in the simple model. Preferential removal of unwanted restrictions supports a lower bar. Additional prompt, audit and review costs can offset some of that benefit.

For example, if one useful exclusion is worth 1.5 times the cost of an extra restriction, and the hatch removes 10% of historical manual matches but 50% of extra restrictions, effective R becomes `1.5 × 0.9 / 0.5 = 2.7`. **The best point-estimate bar becomes 80.** Those removal rates are an illustration, not measured uptake.

There is also a comparison that does not require assigning R: on the recent bound sample, 80 with a hatch retains at least as many manual matches as 83 without a hatch, while leaving no more extra restrictions, if it removes **no more than 12.9% of the manual matches and at least 28.6% of the extra restrictions**. Both conditions must hold. This comparison excludes added prompt costs and does not compare two settings that both have the hatch.

The available MGA `pol_prop_roof_age` field, an internal 360Value field, is blank for all 12,577 quote-homes in the primary cohort. A CAPE recorded roof-year estimate supplies a partial sensitivity check; the column is named `roof_replacement_year`, but its full-replacement meaning is unverified. We simulated removing selections whose recorded year is 2007-2026 and preserving all unknowns. At 83, that removes 16 of the 162 manual matches and 20 of the 125 extra restrictions, leaving **146 matches and 105 extra restrictions**. At assumed value-to-cost ratio 1.5, **83 remains the best integer bar** in this simulation; it also remains the minimax choice over assumed ratios 1-2. Its optimal interval in this simulation is 1.34-1.70.

This is a recorded-recent-year-only removal simulation, not observed agent behavior or verified full replacement. Roof year remains unresolved for 142 of those 146 retained manual matches and 104 of the 105 retained extra restrictions. The data therefore cannot establish actual hatch uptake or rule out stronger selective relief. It does not substantiate the illustrative 50% versus 10% assumption. The year 2006 is held apart because a year alone cannot settle the exact 20-year boundary. See the [escape-hatch evidence](review/threshold_escape_hatch.md) for source coverage and bounds.

## If the actual target is different, use a different number

| Objective | Number supported by the current proxy |
|---|---|
| Balanced starting setting under the explicit effective-R range 1-2 | **83** |
| Approximately one fifth of quote-homes selected before the hatch | **85**, selecting 20.6% |
| Strictly no more than one fifth of quote-homes | **86**, selecting 19.1% |
| Approximately one fifth of quotes with any selected old home | **86**, selecting 20.3% |
| Strictly no more than one fifth of quotes | **87**, selecting 18.7% |
| Match at least 80% of historical manual exclusions in the recent bound subset, before hatch | **66**, matching 81.7% |

Thus 83 is not an “80% of underwriter decisions” solution. It matches about 55% before the hatch in the recent bound subset. If matching most means 80%, that requires a much broader rule and a different cost assessment.

## What to carry forward

Use **83 as the starting recommendation**, and price movement toward 80 with measured hatch outcomes. Measure remaining restrictions, useful protection removed, prompt effort and customer response in the newly admitted bands. Do not assume that the existence of the hatch makes its net cost negligible.

The PRD removes the eligible dwelling-age referral independently of the score threshold. Count that shared workflow benefit once. A lower threshold changes which homes retain exclusions; each additional historical coverage match is not automatically another review avoided.

This remains a current-row analysis. It has not reconstructed decision-time scores, verified form eligibility, randomized customer response, or measured the proposed attestation's accuracy. It changes the recommendation from “we have only a few candidate bars” to **“83 has an explicit, reproducible case as a balanced starting point; stronger selective relief can justify going lower.”**

The complete evidence and reproduction files are the [integer sweep](review/threshold_empirical.md), [decision math](review/threshold_decision_math.md), [escape-hatch analysis](review/threshold_escape_hatch.md), and [reproducible optimizer](review/threshold_decision_math.py). They distinguish executed queries from assumptions and retain the older comparison separately.
