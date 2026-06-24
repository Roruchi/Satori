# Copilot Hooks Audit Demo

This repository includes a demonstration Copilot hooks setup in `.github/hooks/copilot-audit.json`.

The hooks write observe-only audit events to `.copilot-audit/copilot-audit.jsonl` by default. The generated audit directory is gitignored because it can contain prompt and tool metadata from local sessions.

## What Gets Logged

- Session lifecycle: start, end, agent stop, subagent start/stop, compaction, and errors.
- Prompt observability: prompt preview, session id, working directory, and a payload hash.
- Tooling audit: permission requests, successful tool calls, failed tool calls, tool name, sanitized argument previews, result/error previews, and notification events.
- Token usage estimate: approximate input/output token counts based on `ceil(character_count / 4)`.

The token counts are intentionally marked as estimates:

```json
"tokenUsage": {
  "official": false,
  "estimationMethod": "approx_chars_div_4"
}
```

Copilot hook payloads expose prompts, tool arguments, tool results, transcript paths, and lifecycle metadata, but they do not provide official billing-grade token counts in these hook events. This demo keeps the estimate explicit so dashboards do not mistake it for account usage.

## Behavior

The hooks are observe-only. They return `{}` to Copilot and do not allow, deny, block, or modify tool calls or agent output.

Sensitive-looking fields are redacted by key name before previews are written. Keys containing terms such as `token`, `secret`, `password`, `authorization`, `credential`, or `api_key` are replaced with `[REDACTED]`.

## Log Location

Default local path:

```text
.copilot-audit/copilot-audit.jsonl
```

To write elsewhere, set `COPILOT_AUDIT_LOG` before launching Copilot CLI:

```powershell
$env:COPILOT_AUDIT_LOG = "C:\path\to\satori-copilot-audit.jsonl"
```

```bash
export COPILOT_AUDIT_LOG=/path/to/satori-copilot-audit.jsonl
```

For Copilot cloud agent jobs, file output is written inside the ephemeral sandbox. To retain cloud logs outside the job, add a separate HTTPS hook endpoint later and configure the cloud agent firewall allow rule for that endpoint.

## Events Installed

- `sessionStart`
- `userPromptSubmitted`
- `permissionRequest`
- `postToolUse`
- `postToolUseFailure`
- `agentStop`
- `subagentStart`
- `subagentStop`
- `preCompact`
- `errorOccurred`
- `sessionEnd`
- `notification`

`preToolUse` is intentionally not installed for this demo. Command-based `preToolUse` hooks are fail-closed, so a script error or timeout can deny the tool call. This setup focuses on auditability before enforcement.
