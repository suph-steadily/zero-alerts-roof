# Choosing the bar: empirical first read

**The new every-integer sweep supports 83 as a balanced initial setting, conditional on how we value preserved coverage decisions and the escape hatch. It does not make 83 a universal optimum.** In the recent issued-home proxy, 83 is the best setting across all integer bars when one additional matched hand exclusion is worth about 1.30 to 1.91 newly restricted previously-unexcluded homes. The escape hatch can shift that range and justify a lower score. If the goal is to match 80% of historical hand exclusions, the answer is instead 66 in the recent cohort or 63 in the longer historical cohort, before hatch removals.

All fresh queries below ran September 23, 2026, through Metabase database 235, SELECT only, returning public aggregate results. The full point sweep covers every integer 0-101. The primary bootstrap also covers every integer 0-101 with 2,000 policy-clustered draws. This is a first read of current-row coverage signatures, not observed outcomes of the proposed policy.

## How the original analysis got 83

The original analysis took the 80th percentile of the scores on the **pooled-model, bound, 101+ home sample**, created May 1-August 15, 2026. That percentile was 83. Higher scores mean worse roof condition, so score>=83 was intended to cover approximately the worst 20%. The corrected August 21 memo explicitly calls this a capacity heuristic, not an optimum. See [the original explanation](../RESULTS-2026-08-20.md#the-read).

Its historical bar 83 counts were 557 of 1,018 inferred hand exclusions matched, plus 528 homes that previously had no roof exclusion. The arithmetic is correct: 54.72% matched and 528/557=0.948 extra restrictions per match. But the cost of **moving from 85 to 83** was (528-429)/(557-516)=99/41=**2.415**, not 0.948. Moving 83 to 80 cost (682-528)/(618-557)=154/61=**2.525**. Neither result establishes a distinctive optimum at 83.

The earlier September 23 rerun found pooled bound P80=83, while v1.2.0-only bound-home P80 was 81. In current all-quote v1.2.0 homes it was 84; for the maximum score across the qualifying homes on each quote it was 85. Those are different populations and units. See [the executed percentile proxy](../sql/review/baseline_p80_proxy.sql) and [its aggregate log](baseline_runs.json).

Integer ties matter. The operational selector also preserves existing auto exclusions. This follow-up therefore counts the actual fraction selected by `current_auto OR score >= bar` at every integer, rather than treating a percentile as a guarantee of exactly 20% selected.

## Cohorts, labels and grain

- **Historical comparison:** NB creations May 1-August 15, 2026; v1.2.0; creation-year age >= 101 and year built > 1700; all states; current status Issued and issue timestamp before September 23 Chicago. It contains 3,906 homes on 3,392 policy/quote clusters: 741 inferred hand, 3,121 none, 44 auto. The previously recorded baseline had 3,910 homes and 3,125 none, without this fixed issue cutoff. The key 85/83/80 H/N counts are unchanged. Do not equate the two denominators.
- **Primary operating proxy:** NB creations July 30-August 31, 2026; same model and age; CO/RI/WV excluded; Chicago cutoffs. All current traffic has 12,577 homes on 10,993 quotes/policies: 919 hand, 11,469 none, 189 auto. The subset issued before September 23 has 1,597 homes on 1,427 quotes/policies: 295 hand, 1,287 none, 15 auto.
- **Monthly sensitivity:** complete May, June, July and August cohorts under the primary state exclusions. These differ from the historical half-August window. A common issue cutoff is not equal follow-up for binding.
- **Home label:** H means selected coverage without the current auto signature. N means no selected roof exclusion. They are inferred signatures, not verified actors, reviewed negatives or independent roof-quality labels. Auto means coverage selected, flag `yes`, and decision `exclude`.
- **Quote selection:** any qualifying v1.2.0, 101+ home selects the quote. Other homes are outside this cohort. Mixed-home quotes are not forced into a hand/none partition.
- **Nulls and preservation:** a null score never adds a home by score; current auto remains selected. In the audited v1.2.0 populations there are no null/noninteger/out-of-range scores or duplicated quote-home rows. Eligible forms and decision-time state remain unresolved.

Audit: [SQL](../sql/review/threshold_empirical_audit.sql), 9 aggregate rows. Full sweep: [SQL](../sql/review/threshold_empirical_sweep.sql), 1,224 aggregate rows. Both are in [the fresh run log](threshold_empirical_runs.json). [Derived summary](threshold_empirical_summary.json) contains exact inverse targets, capacity cuts, monthly rows and bootstrap summaries.

## Recent and historical coverage curves

H and N count additional score-selected homes. Existing auto remains selected outside H/N.

| Bar | Primary H /295 | Primary N /1,287 | Primary H capture | Historical H /741 | Historical N /3,121 |
|---|---|---|---|---|---|
| 88 | 109 | 56 | 36.95% | 281 | 129 |
| 87 | 119 | 69 | 40.34% | 299 | 152 |
| 86 | 123 | 82 | 41.69% | 314 | 180 |
| 85 | 134 | 97 | 45.42% | 337 | 216 |
| 84 | 146 | 111 | 49.49% | 353 | 240 |
| 83 | 162 | 125 | 54.92% | 375 | 272 |
| 82 | 173 | 146 | 58.64% | 395 | 306 |
| 81 | 180 | 160 | 61.02% | 410 | 341 |
| 80 | 186 | 175 | 63.05% | 427 | 372 |
| 79 | 191 | 189 | 64.75% | 447 | 407 |
| 77 | 199 | 213 | 67.46% | 477 | 465 |

The longer historical 85->83 step still adds 38 H and 56 N. The recent primary step adds 28 H and 28 N; 83->80 then adds 24 H and 50 N. This variation is why the report gives both windows and samples policies for uncertainty. It does not prove the true rollout cost improved over time.

The primary **all-current-quote** steps are much larger: 85->83 adds 54 H and 292 N homes; 83->80 adds 70 H and 429 N. These are real changes in the proposed selection volume, but N includes unreviewed and unbound quotes. It cannot be interpreted as a verified false-positive label. The issued-home ratios above must not be used to forecast this traffic's sales or coverage cost.

## What “match most manual exclusions” requires

This inverse lookup uses every integer, not the older sparse grid. Each bar is the **highest integer achieving the target H capture** in its stated current-row cohort. Target percentages are alternatives, not assumptions about the user's preference.

| Target | Primary bar | Primary H capture | Primary N | Primary quote share | Historical bar | Historical H capture | Historical N |
|---|---|---|---|---|---|---|---|
| 50% | 83 | 162/295 (54.92%) | 125 | 20.04% | 83 | 375/741 (50.61%) | 272 |
| 60% | 81 | 180/295 (61.02%) | 160 | 23.27% | 79 | 447/741 (60.32%) | 407 |
| 70% | 74 | 211/295 (71.53%) | 246 | 30.62% | 73 | 522/741 (70.45%) | 599 |
| 75% | 69 | 224/295 (75.93%) | 300 | 34.62% | 69 | 558/741 (75.30%) | 710 |
| 80% | 66 | 241/295 (81.69%) | 334 | 37.98% | 63 | 597/741 (80.57%) | 870 |
| 90% | 52 | 267/295 (90.51%) | 507 | 49.96% | 50 | 669/741 (90.28%) | 1255 |

Primary quote share includes the 15 existing auto homes and all new H/N selection in the issued subset. It is not a forecast of all quote traffic. At 83, primary H capture is 54.92%, versus 50.61% in the historical cohort. At the primary 80% target, bar 66 matches 241/295 homes and newly restricts 334 previously unexcluded homes. The hatch can reduce both retained H and retained N; these are pre-hatch targets.

## Current traffic and the 20% capacity rule

The primary all-current-quote cohort has 10,993 quotes and 12,577 homes. The selector is the union with existing auto, before any hatch removal.

| Bar | Selected quotes | Quote share | Selected homes | Home share |
|---|---|---|---|---|
| 88 | 1881 | 17.11% | 2023 | 16.08% |
| 87 | 2057 | 18.71% | 2210 | 17.57% |
| 86 | 2229 | 20.28% | 2402 | 19.10% |
| 85 | 2397 | 21.80% | 2593 | 20.62% |
| 84 | 2541 | 23.11% | 2768 | 22.01% |
| 83 | 2701 | 24.57% | 2939 | 23.37% |
| 82 | 2850 | 25.93% | 3108 | 24.71% |
| 81 | 2998 | 27.27% | 3271 | 26.01% |
| 80 | 3150 | 28.65% | 3438 | 27.34% |

For **at most 20% of quotes**, the lowest allowable integer is **87**: 86 selects 20.28%, while 87 selects 18.71%. For **at most 20% of homes**, it is **86**: 85 selects 20.62%, while 86 selects 19.10%. Scores are tied, so no integer exactly achieves 20%. Thus 83 is not the current-traffic 20% cut on either grain.

If the budget means restrictions remaining **after the hatch**, bar 83 would need at least 503 of its 2,701 selected quotes to end with no selected home, leaving at most 2,198 quotes out of 10,993. That is 18.62% of selected quotes. This is required uptake, not observed uptake; removing one home need not clear a multi-home quote. Existing auto treatment must follow the actual hatch design. Gross questions presented and final coverage restricted are different budgets.

## Monthly sensitivity

Complete-month all-quote v1.2.0 traffic, state exclusions as above; the last two columns refer to its issued subset:

| Creation month, 2026 | All-quote homes | Quote share at 83 | Home share at 83 | 20% quote cap bar | Issued H denominator | Issued H capture at 83 |
|---|---|---|---|---|---|---|
| 05 | 222 | 27.32% | 24.77% | 88 | 14 | 64.29% |
| 06 | 10804 | 23.60% | 22.43% | 86 | 313 | 51.44% |
| 07 | 11612 | 25.02% | 23.54% | 87 | 279 | 46.59% |
| 08 | 11601 | 24.56% | 23.28% | 87 | 273 | 55.31% |

May has only 222 v1.2.0 homes and 14 issued H homes, so it has little weight as a stability check. June-August place the quote 20% cap at 86-87, and bar 83 selects about 23.6%-25.0% of quotes. That capacity result is more stable than an exact utility winner. Binding and inferred hand decisions mature, so the issued monthly comparison is descriptive.

## Conditional choice and uncertainty

Use `R*H-N` only as an explicit illustrative value function. R means the net value of a matched hand coverage decision divided by the net cost of restricting a previously unexcluded home. It does not mean a whole underwriting review saved. The PRD removes the eligible dwelling-age alert independently of the bar, so the benefit of that shared routing change cancels when comparing bars.

The full integer frontier gives primary 83 the point-estimate range **1.3023<=R<=1.9091**, versus **1.5789<=R<=1.7000** in the longer historical cohort. Primary 85 and 84 are not strict utility winners for any nonnegative R on this observed integer grid. This favors 83 as the initial balanced candidate, while keeping the valuation and proxy-label limitations visible. See [the decision calculations](threshold_decision_math.py) for full frontiers and the asymmetric escape-hatch model.

With 10% of H removed and 50% of N removed, a hypothetical pre-hatch R=1.5 becomes effective R=1.5*(1-.10)/(1-.50)=2.7. The primary point winner is then 80; the historical winner is 77. Those removal rates are scenarios, not observed eligibility or uptake. At effective R=2.7, nearby primary 79 is only 0.5 scaled utility units behind 80 before multiplying by the retained-N fraction. A reliable whole-number optimum is more precision than that margin supports.

The primary [full-grid policy bootstrap](../sql/review/threshold_empirical_primary_bootstrap.sql) ran 2,000 deterministic Efron draws of 1,427 policy clusters, carrying every eligible home within each sampled policy. [Final aggregate log](threshold_empirical_primary_full_bootstrap_runs.json):

| Effective R scenario | Point winner, conservative ties | Frequent winners across all 0-101 bars | Interpretation |
|---|---|---|---|
| 1.5 | 83 | 83: 45.55%; 82: 13.10%; 88: 12.10%; 87: 11.60%; 85: 0.40% | 83 is the modal balanced candidate; selection uncertainty remains. |
| 2.0 | 82, tied with 81 | 83: 32.65%; 81: 22.70%; 82: 19.30%; 80: 11.90% | Nearby thresholds compete even when their point utilities are close. |
| 2.7 | 80 | 81: 15.10%; 80: 14.00%; 74: 13.75%; 66: 10.05% | A successful selective hatch can favor lower bars, but exact 80 is fragile. |

These frequencies are bootstrap stability under specified R, not probabilities of business success. At 83, primary H-capture 95% interval is 49.19%-60.56%, and N-count interval is 104-148. The bootstrap handles zero-increment steps explicitly: for example 81->80 has zero added H but positive N in 5/2,000 draws, so those step ratios are infinite, not zero or silently omitted. Quantiles are conditional on finite steps and report their eligible counts. Empty feasible-R groups are not evidence of a zero cost.

The historical bootstrap also ran 2,000 draws on 3,392 policies, but only on 70-95 plus existing auto; its [log](threshold_empirical_bootstrap_runs.json) is explicitly restricted-grid. The preliminary 27-bar primary bootstrap is retained in [its own log](threshold_empirical_primary_bootstrap_runs.json), superseded for global winner frequencies by the 102-bar final run. No microstep is presented as a robust new optimum.

A conventional Youden proxy selects 66 in the historical cohort and 64 in the primary issued cohort. This is not a value-free alternative: it implicitly sets R to 3,121/741=4.212 or 1,287/295=4.363 respectively. It also treats coverage signatures as if they were truth labels. Neither condition is justified by the data alone.

## Decision supported by the first read

**83 is a defensible initial joint-policy bar when the aim is a balanced coverage tradeoff.** It matches about half the recorded hand decisions before the hatch, and wins over all integer alternatives over a meaningful conditional value range in the recent issued proxy. A measured selective hatch can support moving lower, including 80 under the scenario above. If “mostly” means 80% retained agreement, the raw score alone needs a much lower bar and the hatch's lost-H rate becomes essential.

The remaining uncertainty is specific: decision-time eligibility, valid manual-decision labels, selective hatch uptake, and sales/loss value. The empirical work has now resolved the integer curve, current capacity cut, inverse matching targets and policy-cluster sampling uncertainty; it does not require pretending those remaining quantities are known.
