---
name: execute-ready-work-item
description: Poll and execute one explicitly approved Satori GitHub issue. Use for the Satori Codex scheduled task that selects the oldest open issue labelled agent:ready and executor:codex, claims it, implements the bounded change, validates it, and opens a draft pull request.
---

# Execute Ready Work Item

## Scope

This skill is a repository-local worker for `Roruchi/Satori`. It does not prioritize the project, create new work, inspect other repositories, or modify Roel's Obsidian vault.

Read `docs/agent-delegation.md` for the project-local delegation protocol and label meanings. Follow `AGENTS.md` as the authoritative implementation and validation policy.

## Select work

1. Query open GitHub issues in this repository.
2. Select only issues with both `agent:ready` and `executor:codex`.
3. Ignore pull requests and issues that already have a `CLAIMED-BY:` comment or a linked open pull request.
4. Select the oldest eligible issue.
5. Process at most one issue per scheduled run. If no issue is eligible, stop without changing anything.

An active issue must have exactly one `agent:*` status label. Do not claim an issue with conflicting status labels.

## Suitability check

Before claiming, confirm that the issue:

- has a bounded outcome and acceptance criteria;
- can be completed entirely inside this repository;
- does not require product, design, security, credential, purchasing, communication, or roadmap decisions;
- does not ask the worker to modify any vault or external planning source;
- is consistent with `AGENTS.md` and repository policies.

If unsuitable, replace `agent:ready` with `agent:blocked` and comment with the exact decision or missing context required. Do not implement partial speculative work.

## Claim

Claim the issue before editing:

1. Add a comment in this form:

   `CLAIMED-BY: codex-satori | CLAIMED-AT: <ISO-8601 timestamp>`

2. Replace `agent:ready` with `agent:running`. Keep `executor:codex`.
3. Re-read the issue after claiming and stop if another worker already claimed it.

## Execute

1. Read `AGENTS.md` and only the files needed for the issue.
2. Create a feature branch following the repository's existing branch conventions.
3. Keep changes strictly within the issue scope.
4. Run the validation required by `AGENTS.md` for the affected files.
5. Do not merge, push directly to the default branch, create unrelated cleanup, or alter repository policy.

## Handoff

On success:

1. Open a draft pull request that links the issue using `Closes #<issue>`.
2. Include the changed files, validation performed, and any limitations in the PR body.
3. Replace `agent:running` with `agent:review`. Keep `executor:codex`.
4. Comment with the draft PR URL and a concise result summary.

On failure:

1. Leave the branch and repository in a recoverable state.
2. Replace the current `agent:*` status with `agent:blocked`. Keep `executor:codex`.
3. Comment with the failed validation, observed evidence, and the smallest action needed to continue.

Do not apply `agent:done`. Only the ChatGPT Chief of Staff may do that after verifying the intended outcome.

## Authority boundary

Only the ChatGPT Chief of Staff may update the central Luna OS delegation registry or any file in Roel's Obsidian vault. This worker reports only through the local GitHub issue and pull request.
