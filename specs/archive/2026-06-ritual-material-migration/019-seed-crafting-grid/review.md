# Pre-Implementation Review

**Feature**: Phase 1 Seed Crafting in 3x3 Grid  
**Artifacts reviewed**: [spec.md](spec.md), [plan.md](plan.md), [tasks.md](tasks.md), [checklists/requirements.md](checklists/requirements.md), [.analyze-done](.analyze-done), [.specify/memory/constitution.md](../../.specify/memory/constitution.md)  
**Review model**: GPT-5.3-Codex  
**Generating model**: Not specified in the reviewed artifacts

## Summary

| Dimension | Verdict | Issues |
|-----------|---------|--------|
| Spec-Plan Alignment | PASS | Plan coverage matches seed-only scope, outcomes, determinism, and mobile touch-target constraints from spec. |
| Plan-Tasks Completeness | FAIL | Ku unlock gating for single-token Ku path is not explicitly implemented in US1 path; task wording scopes gating to dual recipes. |
| Dependency Ordering | WARN | US1 independent-test promise can be undermined because explicit Ku gating implementation appears later in US2. |
| Parallelization Correctness | PASS | Parallel groups are valid, max-3 respected, no same-file collisions inside declared groups. |
| Feasibility & Risk | WARN | Most tasks are right-sized, but cleanup task scope is broad and may create regression risk without tighter acceptance bounds. |
| Standards Compliance | WARN | Constitution requires unlock-reference synchronization discipline; tasks do not explicitly assert whether unlock catalog/reference artifacts remain unchanged or synchronized. |
| Implementation Readiness | WARN | Several execution tasks lack exact runnable commands and concrete evidence format, reducing LLM/operator determinism. |

**Overall**: READY WITH WARNINGS

## Findings

### Critical (FAIL -- must fix before implementing)

1. Ku-gating coverage is incomplete/ambiguous for US1 acceptance behavior.  
The spec requires locked Ku behavior for single-token craft attempts in Phase 1 ([spec.md](spec.md)), including a US1 acceptance scenario. In tasks, explicit gating implementation appears in T020 and is phrased for dual recipes only ([tasks.md](tasks.md)).  
Impact: US1 may not be independently complete/testable as defined.

### Warnings (WARN -- recommend fixing, can proceed)

1. Dependency placement weakens story independence.  
US1 claims independent testability, but explicit locked-element behavior is deferred to later story work ([tasks.md](tasks.md)). This should be foundational or US1-scoped.

2. Constitution traceability for unlock/reference sync is not explicit.  
Given constitution workflow rules for unlock-related changes and living references ([.specify/memory/constitution.md](../../.specify/memory/constitution.md)), tasks should explicitly state either:
- no unlock data changes (assertion), or
- required synchronization/validation updates if mappings are changed.

3. Command-level ambiguity in validation tasks.  
Tasks such as running focused GUT and headless parse checks do not include exact commands or pass/fail artifact format ([tasks.md](tasks.md)).  
Impact: lower reproducibility and inconsistent execution by implementers.

4. Cleanup task is broad.  
"Remove obsolete assumptions and dead branches" is potentially high-risk without precise boundaries ([tasks.md](tasks.md)).  
Impact: regression risk in UI flow and side effects outside Phase 1 scope.

### Observations (informational)

1. Spec, plan, and tasks are generally well-structured and strongly traceable for seed-only scope and out-of-scope structure migration ([spec.md](spec.md), [plan.md](plan.md), [tasks.md](tasks.md)).

2. Parallelization design is disciplined and follows max-3 grouping with sensible file separation ([tasks.md](tasks.md)).

3. Manual validation expectations are well represented, including regression checks for grouped build-confirm and representative non-seed flow ([tasks.md](tasks.md)).

## Recommended Actions

- [ ] Add an explicit task in Foundational or US1 to enforce Ku unlock gating for both single-token and dual-token recipes, and adjust T020 wording to avoid dual-only ambiguity.
- [ ] Ensure US1 test section explicitly includes locked single-token Ku case as part of independent story validation.
- [ ] Add a task note that confirms whether recipe mappings are unchanged vs changed relative to living reference obligations, and include required sync/verification steps if changed.
- [ ] Replace generic validation steps with exact commands and expected evidence format in quickstart/checklist tasks (GUT command, headless parse command, where output is recorded).
- [ ] Split broad cleanup task into explicit sub-tasks with file-level boundaries and concrete acceptance checks to reduce regression risk.
