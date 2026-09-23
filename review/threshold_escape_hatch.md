# Lower bar plus full-roof-replacement escape hatch

The joint policy can reduce the cost of a lower bar, but its value depends on **which exclusions it removes**, not just how many agents answer yes. Bar 83 is reasonable under one explicit range of those assumptions; it is not validated by the existence of the question. A more selective hatch can favor 80 instead, while a hatch that removes the same fraction of historical hand exclusions and previously unexcluded homes leaves the relative threshold tradeoff unchanged before prompt costs.

Seven aggregate/schema SELECT executions completed on September 23 after Metabase reconnected; their results are in [threshold_escape_runs.json](threshold_escape_runs.json). The primary cohort is July 30-August 31 2026 NB quote traffic, creation-year home age 101+, current v1.2.0, CO/RI/WV excluded, Chicago dates, with a separate issued-by-September-22 population. The live result contains 12,577 quote-homes, including 1,597 observed issued homes. Quote-home keys are unique. Current scores and exclusion signatures are not decision-time events, and state exclusions do not establish every eligible form. All query outputs are aggregate counts or schema metadata.

The operational comparison needs the right baseline. If the proposal makes the dwelling-age alert pass through for every eligible 101+ home at every bar, much of the saving from removing age referrals is common to 80, 83, 85 and 90. Do not count an additional saved review for every extra historical hand exclusion that a lower bar captures. Remaining other-alert referrals, prompt effort, response disputes and audits can still differ. Multi-home quotes also mean a home count is not a review count. This follows the proposed routing in [PRD.md](../PRD.md), “Keep the safeguard, lose the referral.”

Let H be a current selected-exclusion signature that lacks the current-auto signature, and N a current unexcluded home. These are historical workflow labels, not proven dangerous and sound roofs. For score bar b, let H_b and N_b be the newly selected counts, and let uH_b and uN_b be the shares whose proposed exclusions the hatch actually removes. Retained counts are H_b(1-uH_b) and N_b(1-uN_b). A coverage-retention surrogate is:

`U_b / C = common_work_savings / C + R × H_b(1-uH_b) − N_b(1-uN_b) − prompt_and_audit_cost_b / C`

Here C is the expected cost of a persistent additional restriction on N, and R is the relative value assigned to retaining coverage protection on H. R must include the common horizon, binding probability, exposure duration and coverage persistence used for C. It is **not** the number of saved underwriter reviews, and the warehouse does not estimate its dollar value. If removed H homes are genuinely safe recent replacements, treating all H removals as lost risk protection overstates their cost. Conversely, a new roof can still have defects. Real-risk valuation therefore needs audited outcomes within the removed and retained groups, not simply their old H/N labels.

The available MGA `pol_prop_roof_age` field is blank on **all 12,577 primary quote-homes**. Its schema describes an internal 360Value age enum `1` through `10`, plus `10+`; even a populated `10+` would not distinguish a 12-year-old roof from a 25-year-old roof. It cannot estimate the proposed full-replacement-within-20-years answer.

CAPE does provide a recorded replacement year on an exact policy/quote/dwelling join: 10,518 of 12,577 homes match, with no duplicate CAPE records at that grain. The distribution is 4,607 years in 2007-2026, 22 in the unresolved 2006 boundary year, 181 older years, 5,708 zeros and 2,059 unmatched homes. Neither a zero nor an unmatched home establishes an old roof. `_loaded_at` is a warehouse load timestamp, not verified evidence of when roof replacement was observed. Source confidence, full-versus-partial replacement meaning and decision-time availability remain unverified.

The most useful empirical sensitivity therefore removes every selected home whose **recorded CAPE year is 2007-2026**, and preserves every other selection, including zero, unmatched and 2006. This is a literal removal simulation, not a forecast of agent uptake or a rule to launch. Existing-auto homes remain a constant outside H/N; there are 15 on the issued subset, including two with recorded recent years.

| Primary issued bar | Selected H / N | Removed H / N under recorded-year simulation | Retained H / N | Retained H / N with unresolved roof year |
|---:|---:|---:|---:|---:|
| 85 | 134 / 97 | 12 / 15 | 122 / 82 | 118 / 81 |
| 83 | 162 / 125 | 16 / 20 | 146 / 105 | 142 / 104 |
| 80 | 186 / 175 | 21 / 29 | 165 / 146 | 161 / 144 |

The simulation supports a concrete sensitivity result: on the full integer grid, **83 is optimal for 1.3429 ≤ R ≤ 1.7000**, before prompt costs, with ties against 87 and 82 at the boundaries. Its no-hatch interval is 1.3023-1.9091. At R=1 the recorded-year simulation chooses 88; at R=1.5 it chooses 83; at R=2 or 2.5 it chooses 82. Thus the measured proxy does not independently establish 83 and actually narrows the range where 83 wins. See the exact optimization in [threshold_decision_math.json](threshold_decision_math.json), with source rows from `threshold_escape_frontier` in this supplement's run log.

At assumed R=1.5, the recorded-year simulation gives 83 utility `1.5×146−105 = 114 C`, versus 101 C at 85 and 101.5 C at 80. Those are conditional coverage-retention units, not dollars saved or reviews avoided. Unknown years dominate the purported retained group: 142/146 H and 104/105 N at 83. The simulation preserves these only by assumption; it does not show that they are truly old roofs or that their agents will answer no.

The newly admitted 83-84 issued band has 28 H and 28 N; CAPE recent years appear on 4 H and 5 N, leaving 24 H versus 23 N. The 80-82 band has 24 H and 50 N; recent years appear on 5 H and 9 N, leaving 19 H versus 41 N. Their local retained N-per-H ratios are 0.9583 and 2.1579. Local ratios do not establish a global optimum: the complete grid contains 87 and 82, which set 83's actual boundaries.

All-quote traffic has a different selection mix. In 83-84, recorded recent years appear on 9/54 H (16.67%) and 55/292 N (18.84%); in 80-82, on 15/70 H (21.43%) and 95/429 N (22.14%). These observed recent-year shares give little selective relief in the marginal traffic. At 83 overall, the all-quote simulation retains 421 H and 1,902 N. The same historical H/N utility applied to all quote traffic is not a forecast: unbound quotes have not completed comparable UW selection, and many will not bind. Its full integer grid does not make 83 optimal for any nonnegative R. This is evidence to separate workflow labels from operational traffic, not a reason to transfer bound-cohort R directly onto quote-stage signatures.

Conditionally treating recorded nonzero years as correct full-replacement years, the bound bar-83 recent-roof eligibility interval would be 16/162 to 158/162 for H (9.88%-97.53%) and 20/125 to 124/125 for N (16.00%-99.20%), allowing every zero, unmatched and boundary year to be recent. These wide intervals do not establish either selective relief or its absence. Without that source-validity assumption, they are not valid truth bounds. Actual answer/removal rates require display, response and acceptance data in addition to roof age.

The material profile is 9,554 asphalt/composition/architectural-coded homes, 1,593 flat-membrane-coded, 123 slate/concrete-coded, 42 tile, 20 wood/shake, three metal-coded, five blank and 1,237 other. These are broad enum mappings, not inspected material truth. Material does not repair the missing roof age: it identifies groups that should be retained in the audit because a sound older durable roof may fail the 20-year question while a defective recent roof may pass it.

The separate legacy Socotra attestation census covers 404,363 quote rows and 19,563 policy rows without a date or MGA-cohort link. No statement matched the joint `roof` and `replac` pattern. Many rows contain other roof statements, which cannot be treated as this replacement question. This census does not prove the absence of a synonym, a different system's question or a proposed new flow; it supplies no measurable hatch uptake.

For comparison with the earlier recommendation, the saved May 1-August 15 issued **all-state** current-v1.2.0 cohort supplies a simpler coarse sensitivity. It is distinct from the primary population above. The saved cohort contains 741 H, 3,125 N and 44 current-auto homes. Its new-score selections are:

| Bar | H selected | N selected | New prompts if every selected home gets the hatch |
|---:|---:|---:|---:|
| 90 | 242 | 94 | 336 |
| 85 | 337 | 216 | 553 |
| 83 | 375 | 272 | 647 |
| 80 | 427 | 372 | 799 |

Source: [baseline_runs.json](baseline_runs.json), `baseline_phase1.sql`, May 1-August 15 / v1.2.0 / all states / 101+. The 44 current-auto homes are held fixed for this comparison. Whether they also get the new hatch is a separate policy choice; if they do and their treatment is identical at every bar, their net contribution is common to the bar comparison but still matters for absolute risk and workload.

For a score band newly admitted by a lower bar, its coverage-retention break-even ratio is `R = ΔN(1-uN_band) / [ΔH(1-uH_band)]`, before additional prompt/audit costs. Use relief within the marginal band, not the overall yes rate. These conditions apply to the same hatch offered at both bars:

| Lowering the bar | Additional H / N | No-hatch N per H | At assumed R=1, minimum N removal share needed |
|---|---:|---:|---|
| 90 to 85 | 95 / 122 | 1.2842 | uN > 22.13% + 77.87% × uH |
| 85 to 83 | 38 / 56 | 1.4737 | uN > 32.14% + 67.86% × uH |
| 83 to 80 | 52 / 100 | 1.9231 | uN > 48.00% + 52.00% × uH |

Equality is a tie before costs. With 25% removal of H in the newly admitted band, 83 needs removal of more than 49.11% of the extra N to beat 85 at R=1; 80 needs more than 61% to beat 83. If uH=1, the band retains no H benefit and this ratio is undefined; positive N or prompt cost cannot be offset by retained H under this surrogate.

If relief rates are constant within each class across all scores and there are no threshold-dependent prompt costs, every bar's ordinary utility curve can be evaluated using `effective_R = R × (1-uH)/(1-uN)`. For uN<1, bar 83 is best **on the saved coarse candidate grid** when effective_R lies between 28/19 = 1.4737 and 25/13 = 1.9231; endpoints tie with 85 and 80. The live integer results above supersede this coarse-grid illustration for the newer primary cohort.

| Assumed R | Assumed H removal | Assumed N removal | Effective R | Best bar on saved coarse grid |
|---:|---:|---:|---:|---:|
| 1 | 0% | 0% | 1.000 | 90 |
| 1 | 10% | 20% | 1.125 | 90 |
| 1 | 10% | 50% | 1.800 | 83 |
| 1 | 0% | 50% | 2.000 | 80 |
| 1 | 50% | 50% | 1.000 | 90 |

These are sensitivity assumptions, not observed yes rates. They show why “the hatch cuts cost in half” is insufficient: it must be more effective at relieving unwanted restrictions than at removing useful protection. They also show that proving an effective hatch does not specifically prove 83.

The joint package can be compared with a higher bar **without** a hatch, which is a different question from choosing the best bar when every candidate has the same hatch:

| Lower bar with hatch versus higher bar without hatch | Maximum H removal for at least as many retained H | Minimum N removal for no more retained N |
|---|---:|---:|
| 83 versus 85 | 10.13% | 20.59% |
| 80 versus 85 | 21.08% | 41.94% |
| 80 versus 83 | 12.18% | 26.88% |

These are aggregate dominance conditions, not risk guarantees. At 83 with assumed uH=10% and uN=50%, expected retained counts are 337.5 H and 136 N, compared with 337 H and 216 N at 85 without a hatch. That combination can preserve the workflow surrogate while reducing extra restrictions by 80 homes. It also presents 647 home prompts, of which 173.5 are assumed accepted, and would generate 17.35 audit triggers at an assumed 10% audit rate. Fractional counts are expectations. All-quote traffic and actual prompt grain are needed to staff it.

Prompt costs can change the choice even when the selective hatch works. Comparing 83 and 85 with that **same** 10%/50% hatch and R=1, the incremental retained counts are 34.2 H and 28 N, leaving only 6.2 C-units of benefit across 94 additional home prompts. If their additional prompt, audit and residual-review cost exceeds 0.06596 C per extra prompted home on average, 83 loses that local comparison. Audit costs should be charged to accepted attestations, with any inspection cost common to both routes kept out of the incremental comparison.

The source catalog distinguishes known columns from unverified meaning and linkage:

| Source | Verified column or stored evidence | What it can establish after profiling | What it cannot establish yet |
|---|---|---|---|
| `dbt.ipod_standard_mga_raw_policy_info` | `pol_prop_roof_age` String, internal 360Value enum; roof type and `_v2` | All 12,577 primary roof ages blank; material aggregate profile available | Full replacement, replacement within 20 years, or a declared answer to the proposed question |
| `dbt.ipod_xmga_vave_dwelling_fire_raw_policy_info` | `insured_item_roof_year_replaced` Nullable(Int32) | Replacement-year data availability in that source | Applicability to Standard MGA homes or a valid cross-source dwelling join |
| `dbt_upc.ipod_policy_mga_cape` | `roof_replacement_year` Int64, exact policy/quote/dwelling keys | 10,518/12,577 linked homes; current recorded-year distribution and literal removal simulation | Independently verified full replacement, source as-of availability, calibrated confidence |
| `dbt.socotra_raw_quote_info` and `_policy_info` | `underwriting_attestation_statement` and `_answer` String | Whether stored statements contain a candidate roof-replacement question and associated answer classes | This exact proposed question, complete prompt denominator, or a join to the current target cohort |
| `dbt.insurance_policy` | Attestation contract ID, created/updated timestamps and status | Contract availability and potentially lifecycle timing | Roof-specific wording, yes response, or actual removal event |
| `tap_veruna.vrna__pl_schedule__c` | `roof_year_formula__c` Float32 | Another roof-year candidate | Original source meaning or event-time truth |
| `tap_veruna.wt_customer_property__c` | `wt_roofing_improvement_year__c` String | Roofing improvement data availability | Full replacement rather than a partial improvement |
| `tap_veruna.inspection__c` | Policy/property key candidates; ordered/received/reviewed fields; `roof_damage_or_structural_concerns__c` Bool | Inspection coverage and roof-concern outcomes after key/timestamp validation | Missing inspections as clean roofs, independent surveillance, or a validated direct join to raw policy IDs |

Column existence is supported by the prior schema reads in [root_runs.json](root_runs.json), `prd_missing_sources`, and the earlier MGA schema investigation. No customer records or raw attestation statements were extracted for this supplement. General remodel or renovation year is deliberately not a substitute for full roof replacement.

The next quantities to verify are true full-replacement eligibility and actual removal rates separately for H and N in score bands 83-84 and 80-82. Let K be a verified recent full-replacement count, U the unresolved count and T the candidate count in a band/class. If confirmed old roofs are ineligible and the verification is correct, full-replacement eligibility is between K/T and (K+U)/T. A declared-age proxy is weaker than this bound until full-replacement semantics are verified. Actual removals additionally depend on question display, response, acceptance and truthfulness; without those assumptions, neither the lower nor upper uptake bound becomes informative beyond 0 to 1. Missing roof age cannot be treated as an old roof or an implicit no answer.

Material matters because an honestly old slate, tile or metal roof can still be in good condition and answer no, leaving an unwanted restriction in place. A roof reported less than 20 years old can also be defective, leaving a truthful yes answer that removes useful coverage protection. The required cross-tab therefore includes age representation, material, score band and H/N signature, then independently observed inspection receipt and roof concerns. Inspection outcomes should be reported per all eligible issued policies and per inspected policies, with the inspection rate alongside both. Validate policy and dwelling joins, multiplicity, inspection timing, and a fixed mature follow-up before interpreting differences. A policy-level cancellation outcome on a multi-home policy cannot be attributed to the roof whose score cleared the bar.

The saved removal and NOC evidence does not estimate this new question's selectivity. September 23 current endorsement removals among 101+ homes were 3/84 for the auto signature and 11/1,677 for the hand signature in the earlier analysis, with neither actor nor full-replacement reason verified. They are not uH or uN. The mature 365-day issue-clock historical 101+ subset had 47/463 Inspection cancellation transactions for H and 769/8,814 for N, risk ratio 1.1635 and Fisher p=0.3117. That comparison is neither score-band-specific nor conditioned on roof replacement, and it does not price prevention. See [memos_runs.json](memos_runs.json), `pushback_september_0` and `noc_issue_full365`.

The executed query files are:

- [threshold_escape_schema.sql](../sql/review/threshold_escape_schema.sql) returned source keys, timestamps and roof-specific fields without exposing record contents.
- [threshold_escape_roof_age_shape.sql](../sql/review/threshold_escape_roof_age_shape.sql) profiled one quote-home per row in the primary cohort, separates zero, under 20, exactly 20, older, calendar-year-looking, unknown and conflicting age values, classifies material, and reports bound versus all-quote counts by score and current signature. Stored roof age is a proxy only. Age 20 is kept separate because integer age cannot resolve the exact date boundary.
- [threshold_escape_attestation_census.sql](../sql/review/threshold_escape_attestation_census.sql) returned only statement-pattern and answer-class counts. Its unwindowed census finds candidate wording; it does not measure target-cohort uptake or prove that a regex match is the proposed statement.

- [threshold_escape_join_schema.sql](../sql/review/threshold_escape_join_schema.sql) resolved CAPE exact keys and its warehouse load timestamp, and documented the Salesforce improvement-year field.
- [threshold_escape_cape.sql](../sql/review/threshold_escape_cape.sql) measured exact-match coverage, default and boundary years, and source multiplicity by score band and signature.
- [threshold_escape_frontier.sql](../sql/review/threshold_escape_frontier.sql) returned the full 0-101 integer simulation for issued and all-quote populations, including selected, removed, retained and unresolved H/N counts.

The deciding evidence for 83 is selective removal in the 83-84 band sufficient to pay for its persistent restrictions and incremental prompt cost, while the 80-82 band fails the same test. If both bands pass, a lower bar deserves consideration. If the hatch removes H as often as N, or older sound materials keep answering no, the question does not create a threshold-specific case for 83. A fixed 20-year statement can still be useful as a workflow policy, but it is not a measured correction for model false positives until those conditional quantities are observed.
