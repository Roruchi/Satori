# Agent Delegation in Satori

## Purpose

Satori uses GitHub Issues as the local work queue for bounded work delegated by Roel's ChatGPT Chief of Staff. A Satori-specific Codex scheduled task polls for suitable issues, processes at most one item per run, and reports through the issue and a draft pull request.

This is a project-local execution workflow. It does not manage Roel's wider priorities and never reads or modifies his Obsidian vault.

## Eligible work

The Codex poller may claim an open issue only when it has both:

- `agent:ready`
- `executor:codex`

The issue must also contain a bounded outcome, scope, acceptance criteria, validation requirements, permissions, and stop conditions. Repository rules in `AGENTS.md` remain authoritative.

## Status labels

An active issue must have exactly one `agent:*` status label.

| Label | Meaning |
|---|---|
| `agent:ready` | Approved and waiting for the Codex poller |
| `agent:running` | Claimed and being implemented |
| `agent:blocked` | A concrete decision or missing dependency prevents progress |
| `agent:review` | A linked draft pull request is ready for review |
| `agent:done` | The outcome has been verified by the Chief of Staff |

`executor:codex` identifies the executor allowed to claim the issue. It remains attached while the work item is active.

Do not accumulate multiple `agent:*` labels. Replace the previous state label during each transition.

## Lifecycle

```text
agent:ready
    -> agent:running
        -> agent:review
            -> agent:done
        -> agent:blocked
    -> agent:blocked
```

### Claim

Before editing, the poller:

1. confirms the issue is suitable and repository-local;
2. adds `CLAIMED-BY: codex-satori | CLAIMED-AT: <ISO-8601 timestamp>`;
3. replaces `agent:ready` with `agent:running`;
4. re-reads the issue and stops if another valid claim already exists.

### Success

The executor:

1. creates a feature branch;
2. performs only the scoped change;
3. follows the validation rules in `AGENTS.md`;
4. opens a draft pull request linked with `Closes #<issue>`;
5. reports changed files, validation, and limitations;
6. replaces `agent:running` with `agent:review`.

The executor never merges and never applies `agent:done`.

### Blocked

When the work is unsuitable or cannot continue, the executor:

1. replaces the current state with `agent:blocked`;
2. comments with the observed evidence;
3. names the smallest concrete decision or missing context required;
4. avoids speculative partial work.

## Authority boundary

Only the ChatGPT Chief of Staff may:

- create approved delegations;
- update the central Luna OS delegation registry;
- modify Roel's Obsidian vault;
- mark work `agent:done` after verifying the outcome.

The Codex poller and repository agents may modify only Satori's local issue, branch, and draft pull request within the granted scope.

## Relevant files

- `AGENTS.md`: repository and validation policy.
- `.agents/skills/execute-ready-work-item/SKILL.md`: Codex polling and execution instructions.
- `.github/ISSUE_TEMPLATE/agent-work.md`: work-item template.
