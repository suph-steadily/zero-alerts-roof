## Attack list disposition

DONE means the requested audit or executable check was performed at the stated scope. SCOPED means the query/design is supplied but required inference, semantic mapping or future follow-up is still open. NOT POSSIBLE means the exact requested result cannot be recovered from the verified sources in this review. A successful current-row query is not a decision-time reconstruction.

| Item | Status | Evidence and remaining work |
|---|---|---|
| A1 | SCOPED | `baseline_phase1.sql` and `baseline_p80_proxy.sql` compare current bound and quote traffic. Historical decision-time tuples and eligibility remain unresolved; no decision-time curve is claimed. |
| A2 | DONE | `memos_q3_collider.sql` restores hand plus none and applies flag-state/date and version cuts. B13/P18 report changed interpretation. |
| A3 | DONE | B3-B7, B13, O1-O6, P17-P20 identify approval and hand-lane selection. The original comparisons are observational. |
| A4 | DONE | `memos_marginal_bind_band.sql` gives current-status counts; `memos_marginal_bind_mature.sql` adds 14/30-day outcomes with Chicago boundaries. In v1.2.0 101+ quote-max 85-89 traffic, treated n=20 remains too thin and selected to price causal bind harm. |
| A5 | DONE | N1-N18 and L1-L16 separate historically selected excluded risks from machine-selected marginal roofs; loss actor provenance is unverified. |
| A6 | SCOPED | New strict-xfail classification tests document both misfiles and rescore problems. `baseline_schema_dependencies.sql` and `prd_missing_sources.sql` discover audit/history sources. Exact actor transition and the 171-row historical decomposition remain unresolved. Current Texas/form diagnostics are in `memos_texas_zero_fire.sql`. |
| A7 | SCOPED | Reviewed-negative requirement is in the proposed classifier/data contract and sister-model dataset. Requires a verified home/version/decision join before a new curve can be called reviewed-only. |
| A8 | SCOPED | Snapshot actor counts can reproduce 22 agent-class removal events; the semantic permission/actor reconciliation needs the producer of f_actor_class and attributed audit transitions. Do not infer customer authority from a label. |
| A9 | SCOPED | `baseline_go_forward_compliance.sql`, `memos_compliance_actual.sql` and schema discovery separate alert gates from review-note events. Roof-specific category mapping is not established. |
| A10 | SCOPED | Additive notes and all new interpretation call the measured endorsement/cancellation a transaction. Actual letter pulls remain blocked on a verified letter source. |
| A11 | DONE | `baseline_zero_106.sql` runs issued and retained-NB predicates, age and flag cuts, score-95 and selected-coverage checks. |
| A12 | SCOPED | `memos_rollout_event_study.sql` supplies within-state weekly aggregates with hygiene dates removed, and original Q4 reproduces the thin April comparison. A fitted event study and parallel-trend assessment remain unrun. |
| A13 | SCOPED | `memos_texas_zero_fire.sql` shows exclude decisions and selected NON_ADMITTED Draft signatures for 101+, plus younger Issued signatures. LD-segment and application-actor mapping remain unresolved. |
| A14 | SCOPED | State exclusions are executable. Exact historical eligible-form and segment maps are unresolved, so proxies are labeled and are not deployment-ready. |
| A15 | SCOPED | New query headers define time, age, version, grain and rollout hygiene. Historical replicas retain original predicates for comparability; sources without event-time/form mappings cannot satisfy the complete target hygiene. |
| A16 | SCOPED | `baseline_phase1.sql` includes v1.2.0 and bar 83; `baseline_coverage_versions.sql` gives monthly mix. Decision-time versus issued-version disagreement remains an A6 dependency. |
| A17 | DONE | `baseline_uniqueness.sql` finds zero noninteger score rows in the specified April-August NB slice. This is a dated check, not a permanent schema guarantee. |
| A18 | DONE | `baseline_monthly_setting.sql` defines monthly inferred application shares with separate home, quote and exclusion denominators. Decision-time actor-verified rate remains the target. |
| A19 | DONE | `baseline_argmax_overlay.sql` keeps coherent issued tuples and outputs April+ denominators and threshold cuts. Proposed overlay change uses distinct policies and explicit bind filters. Original code is unchanged. |
| A20 | DONE | `baseline_uniqueness.sql` verifies issued policy-home uniqueness in the dated extract; it does not certify every future pull. |
| A21 | DONE | Proposed extraction/CLI changes and tests cover an explicit end date, age cut, 83 and display-month mismatch. Originals remain unchanged as requested. |
| A22 | DONE | `branches_loss_exposure.sql` deduplicates homes and aggregates exposure before claims. The original multiplication was also measured; it is small in this current cohort. |
| A23 | DONE | Printed 53,804/47,435=1.1343 quote-homes per quote; live grain verifier is separately recorded in B1. No universal 1.16 factor. |
| A24 | SCOPED | `baseline_snapshot_diagnostics.sql` confirms table existence and cohort/event counts. A filename is not a freeze timestamp; exact load/cutoff provenance remains a limitation. |
| A25 | DONE | `memos_time_to_bind.sql` and `memos_marginal_bind_mature.sql` provide fixed-window mature cuts. Historical mixed-maturity claims retain their caveat. |
| A26 | DONE | S23 and conflict 5 state cutoff-minus-90-day logic. May 22 cannot be inferred from the table name. |
| A27 | DONE | `memos_noc_reason_rates.sql` separates creation/issue clocks; `memos_noc_issue_full365.sql` measures the oldest-at-issue 101+ policies issued by Aug 20 2025: 47/463 hand versus 769/8,814 none Inspection transactions within 365 days through Aug 20 2026. RR=1.1635, not a uniform 1.5-1.6 across eras. |
| A28 | DONE | Corrected loss query uses effective dates and first cancellation spell, Aug 2026 claims-file censor, and paid/incurred outcomes. Reinstatement-inclusive exposure is a separate sensitivity. |
| A29 | DONE | `memos_time_to_bind.sql` reports lane distributions; `prd_referral_latency.sql` measures a different first-decision clock. |
| A30 | SCOPED | `memos_noc_standardization_cells.sql` runs decade cells and `memos_noc_bootstrap.sql` runs 2,000 stratified policy resamples: 1,989 valid, ratio interval 1.323-1.810, expected-count interval 117.601-144.589 for the matched issue-clock 101+ cohort. Inspection-order surveillance remains unresolved. |
| A31 | SCOPED | Corrected loss query includes a $50,000 per-claim capped sensitivity and age cut; schema discovery finds control candidates. A fully adjusted model for Coverage A, deductibles, ACV and age is not fitted. |
| A32 | DONE | B13/O6/P18-P20 explicitly label the original open 90+ band and unpinned versions. |
| A33 | DONE | `baseline_curve_bootstrap.sql` runs 2,000 policy-cluster draws over the entire current v1.2.0 issued 101+ curve, with marginal costs, zero-change handling and global R windows (11 aggregate rows; 3,393 policies). Step intervals overlap. Exact eligible decision-time inference remains an A1/A6 dependency. |
| A34 | SCOPED | Uncertainty section specifies policy clustering and distinguishes already policy-level counts. No claim that aggregate Wilson/Fisher calculations solve cluster dependence. |
| A35 | DONE | 0.051, about 0.07, 0.061 and 0.078 are enumerated; bind and UW-touch pilot endpoints and guardrails are predeclared conceptually. |
| A36 | SCOPED | `branches_loss_sign_test.sql` runs both perils and weakens specificity. The 2,000-draw loss bootstrap was attempted but the connector returned no final output; the successful 10-draw preflight is not a reportable interval. See the SQL header and run log for the actual resource/transport limitation. Dollar/netted intervals remain unverified. |
| A37 | DONE | Claim fixes and 31-conflict table identify mixed ages, grain, clocks, populations and running versus marginal costs. |
| A38 | DONE | Historical status-quo-plus-95 costs 102/227=0.449. In the May 1-Aug 15 101+ bound-home book, existing auto is 59/3.5=16.86/month; the claimed roughly 14/month is not reproduced by the August 101+ cell (2 homes doubled gives 4/month). Replacement versus addition is separated. |
| A39 | SCOPED | `baseline_p80_proxy.sql` runs both grains, versions, auto treatment and null counts. Exact eligible decision-time P80 remains blocked by the historical mapping. |
| A40 | DONE | All primary future cuts use creation-year per-home age; historical fixed-2026, youngest snapshot, oldest policy and effective-year loss figures are labeled. No false single-cohort pooling. |
| A41 | DONE | Age cuts are supplied in overlay, zero-106, compliance, memos and loss checks. Broad original counts retain an all-age label, including the narrower snapshot meaning of the 27% claim. |
| A42 | DONE | `memos_noc_reason_rates.sql` uses policy-years, reports within-101+ rates and Salesforce coverage. A per-home-year claim would require a different denominator. |
| A43 | SCOPED | L1-L4/L13-L15 are restated as descriptive associations; historical applying actor cannot be asserted from current rows. |
| A44 | DONE | Escape-hatch scope covers independent roof-year checks, yes/no distributions, random audits, repeat-agent review, tripwires, material and condition-versus-age gaps. No production experiment is launched. |
| A45 | DONE | `routing_compliance.sql` gives common-cohort current-route proxy and pass-through upper bound. Exact eligibility/residual referral/attestation response is open. State-source review corrects the blanket January 2027 claim. |
| A46 | DONE | P25 and escape-hatch scope tie incremental letter/transaction outcomes to unmeasured attestation behavior. |
| A47 | SCOPED | Baseline, memo and branch query inventories plus PRD source discovery cover missing original numerics. Executable aggregate checks are provided where mappings are known; external estimates, letter outcomes, causal premiums and actor truth cannot be recovered by inventing fields. |
| A48 | DONE | Branch disposition uses three-dot diffs and merge bases. No branch-only files were copied. |
| A49 | DONE | Every corrected/withdrawn ledger row gives replacement meaning; additive notes flag affected main passages. Outward table is for Suph only. |
| A50 | SCOPED | `memos_pushback_october.sql` and `memos_noc_october_60d.sql` specify October re-pulls and September sensitivity. Latest-off versus continuously-off is tested; audit actor and future cutoff are explicitly qualified. |
| A51 | DONE | Decision section defines B, C and R on common expected-dollar/time/traffic units and separates operational catches from coverage-changing over-applies. |

## Prioritized redo list

Effort estimates are planning ranges, not measured engineering time.

1. **Freeze decision-time home tuples, application actors and eligible forms.** About 2-4 analyst/engineer days; warehouse plus event-producer expertise. Unblocks the true curve, actor misclassification, reviewed negatives, exact P80 and deployment population.
2. **Rebuild the mature eligible quote curve and clustered uncertainty.** About 1-2 analyst days after item 1; warehouse required. Include 80/83/85, existing-auto treatment, whole-curve bootstrap and the 85-89 marginal bind band. Unblocks honest capacity and risk tradeoffs.
3. **Agree the value and pilot decision rule.** About one working session plus analysis; warehouse needed for actual operational costs, not to define B/C. Set horizon, bind noninferiority margin, UW-touch benefit and net coverage cost before choosing a production bar.
4. **Run the attestation shadow audit and routing count.** About 2-3 setup days, then enough weeks for responses and audited cases; warehouse plus product/UW access. Unblocks uptake, material exceptions, evidence quality, residual referrals and the pass-through exposure.
5. **Finish outcome identification and uncertainty.** About 2-4 analyst days; warehouse and source owners. Verify letter sources, inspection selection, historical actors, full control-adjusted losses and reinstatement-aware exposure. Unblocks claims about NOC letters, surveillance and marginal dollar value.
6. **Run the scheduled October follow-up.** About half a day once sources are mapped; warehouse required after the chosen cutoff. Re-pull removals with actor/stayed-off checks and the mature auto 60-day cancellation-transaction cohort. Keep longer horizons separate.
7. **Execute the sister-model diagnostic before commissioning a model.** About 3-5 analysis days after item 1, plus blind photo review and label accrual; warehouse required. Use capacity-matched held-out capture to decide age bar, extra features, rule repair or a separate model.
8. **Update outward copies and integrate selected branch material.** About 1-2 hours after choosing approved wording; no warehouse needed. Suph updates the four shared surfaces. A separate change can apply proposed code/SQL fixes and repair branch links; this review preserves originals.
