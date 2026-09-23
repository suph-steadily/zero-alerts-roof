# Threshold choice and the escape hatch: decision arithmetic

This is an extension of Suph's first read, dated September 23, 2026. It uses public aggregate counts only. The reproducible calculation is `review/threshold_decision_math.py`; its output is `review/threshold_decision_math.json`. Run `python3 review/threshold_decision_math.py` from the repo. No database bootstrap is used here.

**83 is a possible choice, not a mathematical optimum established by the first read. A lower bar with a selective escape hatch can beat a higher bar without one. It can also lose useful exclusions if the hatch removes the wrong roofs.** The decision must price retained coverage, customer costs and remaining work together. “Worst 20%” supplies a volume target, not those prices.

**A concrete conditional starting choice is 83, with 80 plus the hatch as the next test.** On the new primary full-integer curve, 83 minimizes worst regret if the effective value ratio is explicitly assumed to lie between 1 and 2. At a base ratio of 1.5, a hatch that removes 10% of historical H-signature selections and 50% of N-signature selections instead makes 80 the point optimum. These value and uptake assumptions are not observed facts. If the objective is a hard 20% limit on gross quote prompts, the measured current-row cutoff is **87**, not 83. All three choices answer different declared objectives.

## The new full-integer calculation

The independent September 23 SELECT returned **1,224 rows**, covering every integer bar 0 through 101 in six creation cohorts and two outcome populations. The primary cohort is new business created July 30 through August 31, 2026, age 101+ by creation year, model v1.2.0, excluding CO/RI/WV. Current rows supply scores and coverage signatures; form eligibility and historical decision-time reconstruction remain unresolved. Its bound-by-September-22 subset has **1,597 homes on 1,427 quotes: H = 295, N = 1,287, auto = 15**. The all-current-quote population has **12,577 homes on 10,993 quotes**. Bound follow-up is not equal across creation dates. The source and executed query are `review/threshold_empirical_runs.json` and `sql/review/threshold_empirical_sweep.sql`.

Maximizing `R*H-N` over all 102 bars gives this primary bound-home frontier near the proposed thresholds:

| Bar | H matches | N restrictions | Range of R making this bar best among every integer |
|---:|---:|---:|---|
| 88 | 109 | 56 | 0.875 to 1.300 |
| 87 | 119 | 69 | 1.300 to 56/43 = 1.30233 |
| 85 | 134 | 97 | No range under this constant-value objective |
| 83 | 162 | 125 | 56/43 = 1.30233 to 21/11 = 1.90909 |
| 82 | 173 | 146 | 21/11 = 1.90909 to 2.000 |
| 81 | 180 | 160 | 2.000 to 2.500 |
| 80 | 186 | 175 | 2.500 to 2.800 |
| 79 | 191 | 189 | 2.800 to 2.850 |
| 74 | 211 | 246 | 2.850 to 44/15 = 2.93333 |
| 66 | 241 | 334 | 44/15 = 2.93333 to 4.000 |

All endpoints are ties. “No range” is a property of these sample counts and this objective, not proof that 85 is never useful in the population, under a budget, with heterogeneous costs or under a different hatch. The omitted bars were still evaluated. At R = 1 the primary point choice is 88; at 1.5 it is 83; at 2 it is a tie between 81 and 82; at 2.7 it is 80; at 3 it is 66. Abrupt jumps reflect a noisy empirical frontier, not causal evidence of abrupt roof-quality changes.

The matched historical May 1 through August 15 all-state, v1.2.0 issued-by-September-22 curve has **3,906 homes: H = 741, N = 3,121, auto = 44**. The earlier live coarse extract had 3,910 homes and N = 3,125; a fixed issue cutoff and refreshed source are not identical extraction semantics. Counts at 85/83/80 are unchanged. On this complete historical grid, 83's optimal range narrows to **30/19 through 17/10, or 1.57895 through 1.70000**, because its binding competitors are 87 and 82. Neither 85 nor 80 is optimal for any nonnegative R under the constant-value model on that historical integer grid. At R = 1.5 choose 87, and at R = 2 choose 77. This is why optimizing only the three named candidates can give a misleading answer.

For a declared robust choice on the **primary** full grid, worst-regret minimization over effective R in [1,2] selects **83**, with maximum regret 16 C units across all 1,597 bound homes. If the declared interval is [1,3], it instead selects **82**, with regret 26 C units; [1.5,2.5] also selects **82**, with regret 4.5 C units. These intervals are judgment calls, not confidence intervals. This supports 83 as an explicitly balanced starting test, not a uniquely learned optimum.

For the **primary all-current-quote** population, preserving all current auto exclusions, bar 83 selects **2,701/10,993 quotes = 24.57%** and bar 80 selects **3,150/10,993 = 28.65%**. Bar 86 still selects 2,229/10,993 = 20.28%; bar **87** selects 2,057/10,993 = 18.71%, making it the lowest integer under a strict 20% gross quote limit. At the home grain, the corresponding strict 20% cutoff is **86**, selecting 2,402/12,577 = 19.10%. These are current-row capacity proxies on the stated state/version/age cut, not fully verified production eligibility. A hatch can reduce retained exclusions while leaving these gross prompt counts unchanged.

The following sections preserve the original sparse-grid arithmetic to explain where 83 came from, then price the hatch explicitly. The full-grid findings above supersede sparse-grid claims of optimality.

## What 83 actually buys

The historical curve covers bound new-business 101+ dwellings created May 1 through August 15, 2026, with model versions pooled. It contains 1,018 inferred hand exclusions, 4,404 left-alone homes and 59 inferred automatic exclusions. The current comparable v1.2.0-only extract, run September 23, has 741 inferred hand exclusions, 3,125 left-alone homes and 44 inferred automatic exclusions, or 3,910 homes. Labels come from current issued rows. They are historical coverage signatures, not verified UW decisions or roof truth.

| Bound-home curve and threshold | Inferred hand coverage matches H | New restrictions on historical left-alone homes N | N/H, cumulative |
|---|---:|---:|---:|
| Original pooled, 85 | 516 | 429 | 0.8314 |
| Original pooled, 83 | 557 | 528 | 0.9479 |
| Original pooled, 80 | 618 | 682 | 1.1036 |
| Current v1.2.0, 85 | 337 | 216 | 0.6409 |
| Current v1.2.0, 83 | 375 | 272 | 0.7253 |
| Current v1.2.0, 80 | 427 | 372 | 0.8712 |

On the original curve, moving **85 to 83** adds 41 H matches and 99 N restrictions: **2.4146 new restrictions per additional match**, not the cumulative 0.9479. Moving **83 to 80** adds 61 H and 154 N: **2.5246 per match**. Comparing 85 directly with 80 costs 253/102 = 2.4804. Choosing from cumulative ratios would mix the relatively inexpensive higher-score homes into the price of the extra band.

On the current v1.2.0 curve, the corresponding marginal prices are 56/38 = **1.4737** for 85 to 83 and 100/52 = **1.9231** for 83 to 80. These are different samples, model cuts and extraction dates, not evidence that the true future price is known to four decimals.

## Choose against every candidate

For a deliberately simplified, constant-value objective, let B be the value of a retained desirable H-signature exclusion and C be the net cost of a retained N-signature restriction. This use of B concerns coverage retained under pass-through. It is **not automatically the memo's saved UW-touch benefit**. C already nets any justified incremental paid-loss benefit from that restriction. The labels alone do not establish that H is desirable or N is costly.

If B and C are constant across the compared homes and C > 0, put R = B/C and maximize:

`U(T)/C = R * H(T) - N(T)`.

The script solves every pairwise inequality for every candidate, including no new score rule while retaining the existing auto lane. Endpoints are ties. Values outside the table can select other bars.

| Curve | 85 is best on the printed grid when R is | 83 is best when R is | 80 is best when R is |
|---|---|---|---|
| Original pooled bound homes | 185/122 to 99/41 = 1.5164 to 2.4146 | 99/41 to 154/61 = 2.4146 to 2.5246 | 154/61 to 245/89 = 2.5246 to 2.7528 |
| Current v1.2.0 bound homes | 122/95 to 28/19 = 1.2842 to 1.4737 | 28/19 to 25/13 = 1.4737 to 1.9231 | 25/13 to 167/67 = 1.9231 to 2.4925 |

These are **global optima on the printed ten-bar grid only**, not a claim about every integer or future traffic. The independently queried integer grid is processed separately below. Exact arithmetic does not remove sampling uncertainty. The prior policy-cluster bootstrap of the coarse v1.2.0 curve found a nonempty 83-optimal interval in 1,645 of 2,000 draws, not every draw. It does not validate H/N as truth, decision-time score reconstruction or deployment transport.

Do not use a greedy rule that stops at the first unattractive step. On the original grid, the 65 to 60 step costs 223/34 = 6.5588 while 60 to 55 costs 229/38 = 6.0263. At R = 6.3, the combined 65 to 55 move is favorable because 452/72 = 6.2778. Global optimization selects 55; a greedy walk could stop at 65. Bar 60 is never the global best on that grid for any nonnegative R. The script uses rational numbers, preserving ties and avoiding decisions based on rounded slider values.

If C is zero or negative, or values change by score/material/state, use dollar utility directly. A ratio-based stopping rule no longer supplies the answer. Even when C is positive, existing auto coverage must be retained by an explicit union rule or the value of removed auto exclusions must be added to the comparison.

This is the mathematical implication of the “cheap persistent cost plus escape hatch” thesis: lowering the net cost of the N group makes a lower bar more attractive, all else equal. If that net cost actually reaches zero or becomes a benefit, retained H has nonnegative value, and added prompts/reviews impose no offsetting cost, this simplified model keeps favoring broader selection. It does not single out 83, 80 or any intermediate knee. A finite optimum then needs a genuine cost, budget, risk constraint or declining score-specific benefit. The first read does not establish those zero-cost premises.

## Why the 80th percentile does not prove 83

The original “83” claim came from the pooled bound-home 80th percentile. The current comparable pooled extract still has P80 = 83, with 1,189 of 5,761 scored homes at or above 83, or 20.6388%; including 28 unscored homes in the denominator gives 1,189/5,789 = 20.5390%. Score ties explain why a percentile threshold need not select exactly 20%.

With v1.2.0 alone, P80 changes to **81 for 3,910 bound homes**, **84 for 28,978 quote-homes**, and **85 for 25,368 quotes using the maximum among 101+ homes**. All three cuts cover current rows from the same May 1 through August 15 creation window and include current auto homes in the score distribution. At bar 83 they respectively select 690/3,910 = 17.65%, 6,524/28,978 = 22.51%, and 6,036/25,368 = 23.79%. Dropping existing auto homes changes these quantiles again. These figures come from `baseline_p80_proxy.sql`; they count the score cut, not the union with all current auto exclusions.

Thus 83 can reproduce a historical pooled-bound percentile but cannot honestly be called the worst 20% of current eligible decision-time quotes. A strict 20% budget needs the actual quote denominator, a tie convention and the union with retained current auto coverage. For a monotone threshold and a hard “at most 20%” limit, select the lowest threshold satisfying that limit. If an entire tied score would exceed the budget, raise the threshold or predeclare an appropriate within-tie rule; do not silently claim exact 20%. A percentile or capacity choice still is not a net-value optimum.

## Lower bar plus escape hatch

Let u_H and u_N be the accepted removal fractions among selected H and N homes. Neither is measured for the proposed hatch. They include the response rate and the probability a yes answer actually removes the exclusion. Do not mistake overall uptake for the two conditional rates.

Under the narrow retained-coverage objective, retained H is `(1-u_H)*H`, retained N is `(1-u_N)*N`, and the effective price is:

`R_effective = R * (1-u_H) / (1-u_N)`.

This identity requires constant rates across the score bands, positive remaining N fraction and no prompt, audit or other incremental cost. With it, apply the same global optimizer at R_effective. When u_N = 1, compare utilities directly instead of dividing by zero.

* Removing a larger share of N than H shifts the coverage tradeoff toward a lower threshold.
* Equal removal fractions preserve the preferred threshold under this limited objective and scale its utility. They still remove useful exclusions and create work.
* Removing a larger share of H than N shifts toward a higher threshold.

For example, at the **assumed** base R = 1.5 on the primary full-integer bound-home curve, no hatch selects 83. Removing 10% of H and 50% of N gives R_effective = 2.7 and selects **80**. Removing 50% of both still selects 83. Removing 50% of H but only 10% of N gives R_effective = 0.8333 and selects **89**. These are sensitivity examples, not observed uptake or proof of optimal deployment. In the earlier historical full-integer cohort, the same 10%/50% hatch at R = 1.5 selects 77, illustrating transport risk.

The exact primary full-grid condition for **83 with a hatch** is `56/43 <= R*(1-u_H)/(1-u_N) <= 21/11`. Holding the assumed R at 1 and H removal at 10%, 83 is best when N removal is between **30.89% and 52.86%**, with ties at the endpoints and zero prompt/audit costs. At R = 1.5 and H removal 10%, the condition becomes N removal between zero and **29.29%** after intersecting the algebraic interval with feasible probabilities. The illustrative 50% N removal exceeds that window and supports going below 83. A successful escape hatch does not uniquely validate 83.

| Assumed R on primary full-integer bound curve | H removal | N removal | Effective R | Best integer bar |
|---:|---:|---:|---:|---:|
| 1.0 | 0% | 0% | 1.00 | 88 |
| 1.0 | 10% | 50% | 1.80 | 83 |
| 1.5 | 0% | 0% | 1.50 | 83 |
| 1.5 | 10% | 50% | 2.70 | 80 |
| 1.5 | 50% | 50% | 1.50 | 83 |
| 1.5 | 50% | 10% | 0.8333 | 89 |
| 2.0 | 0% | 0% | 2.00 | 81 and 82 tie |

At assumed R = 1.5 with that 10%/50% hatch, bar 80's whole-primary-cohort utility is 163.60 C units, versus 163.35 at 79 and 163.00 at 81. The exact point advantage is tiny. A prompt cost above C/35 per newly selected home already makes 81 preferable to 80, holding all other assumptions fixed. The right interpretation is a region to test, not a durable optimum at precisely 80.

There is a more actionable comparison that does not require a chosen R. A lower bar with a hatch improves both proxy counts over a higher bar **without** a hatch if it retains at least as many H matches and leaves no more N restrictions. For the primary July 30 through August 31 v1.2.0 cohort issued by September 22:

| Lower bar with hatch versus higher bar without | Maximum H removal fraction to preserve H count | Minimum N removal fraction to avoid more N restrictions |
|---|---:|---:|
| 83 versus 85 | 28/162 = 17.28% | 28/125 = 22.40% |
| 80 versus 85 | 52/186 = 27.96% | 78/175 = 44.57% |
| 80 versus 83 | 24/186 = 12.90% | 50/175 = 28.57% |

Both conditions must hold. They compare marginal new score selections while preserving all 15 current automatic exclusions without a hatch in this primary illustration. They do not show lower customer cost after prompts/audits, prove roof correctness or compare two policies that both offer a hatch. On the historical current v1.2.0 curve, the 80-versus-85 conditions were H removal at most 21.08% and N removal at least 41.94%; on the original pooled curve they were 16.50% and 37.10%. Population choice matters.

At the **assumed** 10% H and 50% N removal rates, the primary bound cohort would have:

| Bar | New prompt homes | Retained H | Retained N | Accepted removals | Total excluded homes including 15 preserved auto | Audit triggers if 10% of accepted removals audited |
|---|---:|---:|---:|---:|---:|---:|
| 85 | 231 | 120.6 | 48.5 | 61.9 | 184.1 | 6.19 |
| 83 | 287 | 145.8 | 62.5 | 78.7 | 223.3 | 7.87 |
| 80 | 361 | 167.4 | 87.5 | 106.1 | 269.9 | 10.61 |

Fractional counts are expectations under stated assumptions. Bar 80 plus this hatch retains more H than 83 without a hatch (167.4 versus 162) while leaving fewer N restrictions (87.5 versus 125), but generates 361 new prompt homes versus 287 newly selected homes at 83. If the higher-bar comparator has no attestation prompt, all lower-bar prompts and processing costs are additional. If it also offers a hatch, compare its corresponding row instead. If existing auto selections also receive the hatch, add their expected removals and costs; because this lane is retained at every bar, its contribution is constant for threshold ranking but still matters against today's workflow.

Truthful roof-replacement attestation and a sound roof are distinct labels. A new roof can be defective. An old slate, tile or metal roof can be sound and honestly fail the 20-year question. Count accepted legitimate removals, factual misstatements, truthful but unsuitable removals and unresolved evidence separately. Do not equate the inferred H group with erroneous removals or the N group with legitimate removals.

The hatch also changes who remains restricted. If retained roofs have different expected losses or customer costs from removed roofs, B and C must be re-estimated for those retained cells; shrinking counts while keeping the original average values is only a sensitivity model. This selection can strengthen or weaken the case for going lower.

## What the recorded roof-year proxy actually changes

The independent roof-year sensitivity returns every integer bar on the same primary cohort. It removes every selected home with a recorded CAPE roof year from 2007 through 2026 and retains restrictions when the year is missing, unmatched or at the unresolved 2006 boundary. This is a **literal recorded-year counterfactual**, not observed attestation uptake, verified full replacement, source confidence or an as-of decision-time roof-year fact. The available MGA `pol_prop_roof_age` field, an internal 360Value field, is blank across all 12,577 primary quote-homes. See `review/threshold_escape_hatch.md` and `review/threshold_escape_runs.json`.

On the 1,597 primary bound homes:

| Bar | Selected H / N | Removed H / N by recorded-year proxy | Retained H / N |
|---:|---:|---:|---:|
| 85 | 134 / 97 | 12 / 15 | 122 / 82 |
| 83 | 162 / 125 | 16 / 20 | 146 / 105 |
| 80 | 186 / 175 | 21 / 29 | 165 / 146 |

At 83 the proxy removes 16/162 = 9.88% of H and 20/125 = 16.00% of N, far short of the illustrative 50% N relief. Across every integer bar, the resulting **83-optimal range is 47/35 through 17/10, or 1.34286 through 1.70000**. At R = 1.5, **83 still wins**; at R = 2 or 2.5, choose 82. Bar 80 is best only from 8/3 through 11/4, or 2.66667 through 2.75000. These R values price the retained groups directly, with no second uniform hatch multiplier. Minimax regret over declared R in [1,2] still selects **83**, with regret 13 C units. Over [1,3] it selects 82, with regret 20 C units.

The actual recorded-year counterfactual therefore does **not** move the R = 1.5 recommendation to 80. At that price, 83's utility is 114 C units versus 101.5 at 80. Bar 80 with this proxy also fails to match the no-more-N condition against 83 without a hatch: it retains 165 H versus 162, but 146 N versus 125. A more effective, selective real attestation could still change that conclusion. The data have not shown one yet.

Two of the 15 existing auto homes meet the recent-year proxy. If they also receive automatic removal, add their common contribution to every bar. This does not change the ranking but changes total coverage and the comparison with today's workflow. Do not apply the proxy rates twice or relabel missing roof years as old roofs.

## Workload and loss exposure need their own accounting

**Under the proposed PRD, removing the 101+ age referral saves its work independently of the score threshold.** That common benefit is not 134, 162 or 186 saved UW touches. Those numbers count matched coverage signatures among primary bound homes at bars 85, 83 and 80. Other alerts can still require a review. Several homes can share a quote or review, and a reviewer can spend time without changing coverage.

If instead the rule only bypasses review for flagged homes while all below-bar homes retain current routing, score selection can change review work. Measure saved reviews and handling time among both H and N, with a quote-level union for other alerts. That is a different product from full age-alert pass-through. An attester can still bypass review while having the exclusion removed, so do not multiply all saved operational value by `(1-u_H)`.

For full pass-through, define K as the total value of age-review work and conversion improvement genuinely saved after allowing for other alerts. A simplified comparison with today's coverage, assuming historical H exclusions really should stay in place, is:

`U_change(T) = K - B*[H_total - (1-u_H)*H(T)] - C*(1-u_N)*N(T) - new_prompt_and_review_costs`.

K is common across thresholds, so it does not affect their ranking, but it determines whether any pass-through proposal beats today's routing. The script's zero-selection comparator is **pass-through with no new score rule**, not a measured net-zero status quo. To choose production over today's workflow, the full comparison above must also be positive. If some historical H exclusions are unwarranted, replace their assumed B with measured score-specific value rather than charging every removal as a loss.

For the primary bound-home illustration with no hatch, bar 80 leaves 295-186 = 109 H signatures without the previously observed exclusion. At assumed R = 1.5, the simplified break-even common benefit is `K/C >= 1.5*109+175 = 338.5`, before new operating costs. Under assumed u_H = 10%, u_N = 50%, bar 80 leaves 127.6 H signatures without the exclusion, and the corresponding break-even is `K/C >= 1.5*127.6+87.5 = 278.9`. These are normalized whole-cohort values, not dollar estimates or saved review counts.

Prompt-home counts are not home-years. To turn marginal coverage changes into expected paid loss, use each score/state/material cell's probability of binding, expected covered duration and exclusion persistence. For example, retained new restriction exposure is `sum(n * p_bind * covered_years * p_exclusion_retained)` over the relevant quote-home cells. Deduplicate policy spells; use coherent coverage events. Lower-bar homes, attesters and nonattesters need not share these factors. Report both gross prompts and net retained restrictions, then actual expected insured exposure. Do not multiply all quote prompts by a historical bound-book annual loss number.

The corrected historical loss read has a descriptive netted paid difference of $79.60 per matched excluded home-year in its 101+ January 2024 through June 2026 creation cohort, with claims observed through the August 2026 file. This is not a causal saving, a marginal score-band value or an upper bound. Only one of ten excluded 101+ wind/hail claims had a score. The loss-bootstrap delivery failed, so there is no reportable loss CI available to price this decision. No loss query was rerun for this extension.

## The general objective to measure

For each score and historical-signature cell, estimate all quantities on the same eligible quote population and horizon. Let n be its population; a_L the probability of an accepted legitimate removal; a_E the probability of an accepted erroneous or unsuitable removal; and r = 1-a_L-a_E the retained fraction. “Legitimate” here means the coverage decision is appropriate, not merely that the roof-replacement answer is factually true.

One transparent per-selected-home value, relative to pass-through without a new restriction, is:

`v = threshold_specific_review_savings + r*(paid_loss_protection - retained_customer_cost) - a_L*legitimate_removal_processing_cost - a_E*extra_error_cost - prompt_cost - residual_review_probability*review_cost`.

Then maximize `common_work_savings + sum(n*v)` over **every** candidate bar. The Python `general_utility` function implements this accounting. Conversion/retention contribution, service/complaint/disclosure costs and coverage persistence belong in the state-appropriate costs. Costs caused before an attestation removes coverage must remain in prompt or removal costs. Extra error cost excludes the same loss protection already forgone when r falls; otherwise the model double counts it. If removal leads to an inspection or referral, include that probability and handling cost explicitly.

Home-level summation is appropriate only for additive values or costs correctly allocated to homes. A lost bind, fixed review or complaint can happen once per quote even when several homes are flagged. For those items, the exact objective is `K + sum(home-level expected coverage value) - sum(quote-level expected customer and operating costs)` at each bar. Use the quote union and allocate fixed costs once, or calculate that quote total directly. The empirical home H/N counts must not be multiplied by a full per-quote bind or review cost on every home.

A flat prompt cost changes the threshold even if the hatch has equal uptake. In units of C, with prompt cost k per selected home and the simple H/N objective, maximize:

`[R*(1-u_H)-k]*H - [(1-u_N)+k]*N`.

When the denominator is positive, this is the original optimizer at `[R*(1-u_H)-k]/[(1-u_N)+k]`. Audit costs per accepted removal introduce different H and N terms if uptake differs. If the numerator is negative, directly compare every candidate including no new score rule. The universal claim “an escape hatch makes a lower bar safe” does not follow.

## Conditional choices and uncertainty

A useful conditional recommendation has an objective attached. The primary full-grid point estimate and declared minimax calculation support **83 as a balanced starting test**, with **80 plus the hatch** supported only by stronger selective relief or a higher value ratio. The recorded roof-year sensitivity preserves the R = 1.5 choice of 83. These are reproducible choices under stated assumptions, not an estimated business exchange rate.

If the product decision instead sets a hard quote-prompt capacity of 20%, the measured primary current-row union requires **87**. A successful hatch may lower retained coverage burden but does not remove the original prompt. Define a separate net-restriction budget if that is the intended constraint. The earlier pooled-bound percentile at 83 and earlier v1.2.0 quote P80 of 85 do not describe this current traffic capacity rule.

A robust rule still needs an explicit uncertainty set. The declared [1,2] range is a decision assumption, not a CI inferred from the loss or bind read. Worst regret is the gap from the best bar at the same R, and for this linear model its maximum over an interval occurs at an endpoint. The script optimizes that regret across every bar, including bars that are never individually optimal at a fixed R. A compromise can minimize regret without being a point optimum. Do not present an unstated minimax preference as an empirically ideal threshold.

This minimax calculation uses a fixed normalized cost unit. If C or the retained fraction varies across uncertainty scenarios, dollar regret must carry that scale too; a ratio alone does not specify a dollar minimax problem.

The independent **2,000-draw policy-cluster bootstrap across all 102 bars**, using the primary 1,427 policy clusters, makes the sampling uncertainty concrete. Bar 83's pre-hatch H capture is 162/295 = 54.92%, with a 95% bootstrap percentile interval of **49.19% to 60.56%**. Bar 80's capture is 186/295 = 63.05%, with interval **57.29% to 69.16%**. At fixed effective R = 1.5, 83 is the selected bar in **911/2,000 = 45.55%** of draws. At 2.7, 80 is selected in **280/2,000 = 14.00%**, while 81 is selected in 302/2,000 = 15.10%, 79 in 190/2,000 = 9.50%, and other bars take the remaining selections. These frequencies follow the query's declared tie rule and measure sampling instability, not the probability a bar is truly optimal. The complete output is `review/threshold_empirical_primary_full_bootstrap_runs.json`. It supersedes the preliminary restricted 70-95 grid for global selection frequencies.

No unmeasured hatch uptake, error rate, marginal avoided loss, customer cost or residual workload is set to zero as a finding. Those zeros only define the explicitly labeled surrogate calculations. Before a broader rollout, measure the two conditional removal rates by score band and independent roof grade, fixed-window bind/contribution, remaining review minutes, retained coverage and resulting cancellation/complaint outcomes. Score alone cannot establish that an excluded home was protected from a NOC or that a removal was safe.

## Reproduction and limits

The script now reads the completed 1,224-row integer sweep and 204-row recorded-roof-year sensitivity. It evaluates every returned bar for each cohort/population, computes global optimality intervals, and reports the lowest bar under a 20% home or quote union budget. It keeps the no-new-score-rule comparison. The source curves, point choices, tie endpoints, minimax examples and hatch-count illustrations are saved in `review/threshold_decision_math.json`. Six independent synthetic optimizer and utility checks in `tests/test_threshold_decision_math.py` pass.

All-quote H/N fields remain descriptive current-row signatures; unbound no-exclusion homes are not verified UW negatives. Applying the bound-home R directly to the much larger unbound N group is not a valid decision-time utility estimate. The script retains those aggregate curves for transparency but does not recommend their naive price optimum. Bootstrap uncertainty does not correct survivor selection, label errors, unresolved form eligibility, decision-time leakage or unmeasured hatch behavior. Those are the limits on turning this conditional recommendation into a production setting.
